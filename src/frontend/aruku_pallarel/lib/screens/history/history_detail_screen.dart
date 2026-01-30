import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../features/history/provider/walk_history_provider.dart';
import '../../features/walk/models/walk_suggest.dart';
import '../../features/walk/provider/walk_suggestion_provider.dart';
import '../../features/walk/utils/map_utils.dart';
import '../../screens/chat/chat_screen.dart';
import '../../router/app_router.dart';
import '../../theme/map_theme_provider.dart';
import '../../theme/map_tiles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_floating_button.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';
import '../walk/widgets/walk_bottom_overlay.dart';
import '../walk/widgets/walk_info_header.dart';
import '../walk/widgets/walk_map_layer.dart';
import '../walk/widgets/walk_suggest_pin.dart';

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
  bool _didInvalidate = false;
  String? _selectedSuggestId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidate) {
      return;
    }
    _didInvalidate = true;
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

  WalkHistoryItem? _findHistoryItem(List<WalkHistoryItem>? items) {
    if (items == null) {
      return null;
    }
    for (final item in items) {
      if (item.walkId == widget.walkId) {
        return item;
      }
    }
    return null;
  }

  int? _calculateElapsedMinutes(WalkHistoryItem? item) {
    final startedAt = item?.startedAt;
    final finishedAt = item?.finishedAt;
    if (startedAt == null || finishedAt == null) {
      return null;
    }
    final minutes = finishedAt.difference(startedAt).inMinutes;
    if (minutes < 0) {
      return null;
    }
    return minutes;
  }

  List<Marker> _buildSuggestMarkers(List<WalkSuggest> suggests) {
    return suggests
        .map(
          (suggest) => Marker(
            point: suggest.position,
            width: 44,
            height: 44,
            child: WalkSuggestPin(
              isSelected: suggest.suggestId == _selectedSuggestId,
              onTap: () {
                setState(() {
                  _selectedSuggestId = suggest.suggestId;
                });
              },
            ),
          ),
        )
        .toList();
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          walkIdOverride: widget.walkId,
          readOnly: true,
        ),
      ),
    );
  }

  void _backToHome(BuildContext context) {
    context.router.replaceAll(const [HomeRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync =
        ref.watch(walkHistoryRouteNotifierProvider(widget.walkId));
    final historyListAsync = ref.watch(walkHistoryListNotifierProvider);
    final historyItem = _findHistoryItem(historyListAsync.valueOrNull);
    final mapThemeId = ref.watch(mapThemeNotifierProvider);
    final mapTheme = mapThemeId.theme;
    final suggestsAsync = ref.watch(walkSuggestListProvider(widget.walkId));

    return Scaffold(
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

          final distanceKm = MapUtils.calculateRouteDistanceKm(points);
          final elapsedMinutes = _calculateElapsedMinutes(historyItem);
          final center = points.last;
          final suggestMarkers = suggestsAsync.when(
            data: _buildSuggestMarkers,
            loading: () => const <Marker>[],
            error: (error, stackTrace) => const <Marker>[],
          );
          const notices = <Widget>[];

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: WalkMapLayer(
                      mapController: _mapController,
                      center: center,
                      onPositionChanged: (position, hasGesture) {},
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
                      urlTemplate: mapTheme.urlTemplate,
                      subdomains: mapTheme.subdomains,
                      routePoints: points,
                      suggestMarkers: suggestMarkers,
                      heading: null,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 8,
                child: SafeArea(
                  bottom: false,
                  child: WalkInfoHeader(
                    distanceKm: distanceKm,
                    elapsedMinutes: elapsedMinutes,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: WalkBottomOverlay(
                    notices: notices,
                    mainButtonLabel: 'ホームに戻る',
                    isMainButtonLoading: false,
                    onMainButtonPressed: () => _backToHome(context),
                  ),
                ),
              ),
              Positioned(
                left: 28,
                bottom: 28,
                child: SafeArea(
                  top: false,
                  right: false,
                  child: AppFloatingButton(
                    icon: Icons.chat,
                    onTap: () => _openChat(context),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: SafeArea(
                  left: false,
                  bottom: false,
                  minimum: const EdgeInsets.only(top: 1, right: 1),
                  child: MapInfoButton(
                    onTap: () => showMapAttributionSheet(context, mapThemeId),
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
