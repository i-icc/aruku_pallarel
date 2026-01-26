import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../features/history/provider/walk_history_provider.dart';
import '../../theme/app_styles.dart';
import '../../theme/map_tiles.dart';
import '../../theme/map_theme_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';

@RoutePage()
class HistoryDetailScreen extends ConsumerStatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.walkId,
  });

  final String walkId;

  @override
  ConsumerState<HistoryDetailScreen> createState() =>
      _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  LatLngBounds? _pendingBounds;
  LatLng? _pendingCenter;

  @override
  void initState() {
    super.initState();
    ref.invalidate(walkHistoryRouteNotifierProvider(widget.walkId));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _applyBounds(LatLngBounds bounds) {
    if (!_mapReady) {
      _pendingBounds = bounds;
      _pendingCenter = null;
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  void _applyCenter(LatLng center) {
    if (!_mapReady) {
      _pendingCenter = center;
      _pendingBounds = null;
      return;
    }
    _mapController.move(center, _safeZoom());
  }

  double _safeZoom({double fallback = 15}) {
    final zoom = _mapController.camera.zoom;
    if (zoom.isFinite) {
      return zoom;
    }
    return fallback;
  }

  bool _hasArea(LatLngBounds bounds) {
    const epsilon = 0.000001;
    final latSpan = (bounds.north - bounds.south).abs();
    final lonSpan = (bounds.east - bounds.west).abs();
    return latSpan > epsilon || lonSpan > epsilon;
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync =
        ref.watch(walkHistoryRouteNotifierProvider(widget.walkId));
    final mapThemeId = ref.watch(mapThemeNotifierProvider);
    final mapTheme = mapThemeId.theme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Detail'),
      ),
      body: routeAsync.when(
        data: (points) {
          if (points.isEmpty) {
            return const AppBackground(
              safeAreaTop: false,
              child: Center(
                child: Text('No locations recorded for this walk.'),
              ),
            );
          }
          final bounds = LatLngBounds.fromPoints(points);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (_hasArea(bounds)) {
              _applyBounds(bounds);
            } else {
              _applyCenter(points.first);
            }
          });
          final start = points.first;
          final end = points.last;
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: start,
                        initialZoom: 15,
                        onMapReady: () {
                          _mapReady = true;
                          final pending = _pendingBounds;
                          if (pending != null) {
                            _pendingBounds = null;
                            _applyBounds(pending);
                            return;
                          }
                          final pendingCenter = _pendingCenter;
                          if (pendingCenter != null) {
                            _pendingCenter = null;
                            _applyCenter(pendingCenter);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: mapTheme.urlTemplate,
                          subdomains: mapTheme.subdomains,
                          userAgentPackageName: 'com.example.arukuPallarel',
                        ),
                        if (points.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: points,
                                strokeWidth: 4,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: start,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.flag,
                                color: AppColors.success,
                              ),
                            ),
                            Marker(
                              point: end,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.flag,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SafeArea(
                        left: false,
                        bottom: false,
                        minimum: const EdgeInsets.only(top: 8, right: 8),
                        child: MapInfoButton(
                          onTap: () =>
                              showMapAttributionSheet(context, mapThemeId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.base,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Walk ID: ${widget.walkId}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Points: ${points.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _CoordinateChip(
                                  label: 'START',
                                  lat: start.latitude,
                                  lon: start.longitude,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CoordinateChip(
                                  label: 'END',
                                  lat: end.latitude,
                                  lon: end.longitude,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppBackground(
          safeAreaTop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => AppBackground(
          safeAreaTop: false,
          child: Center(
            child: Text('Failed to load route: $error'),
          ),
        ),
      ),
    );
  }
}

class _CoordinateChip extends StatelessWidget {
  const _CoordinateChip({
    required this.label,
    required this.lat,
    required this.lon,
  });

  final String label;
  final double lat;
  final double lon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
          style: textTheme.bodySmall?.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}
