import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/history/provider/walk_history_provider.dart';

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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _applyBounds(LatLngBounds bounds) {
    if (!_mapReady) {
      _pendingBounds = bounds;
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync =
        ref.watch(walkHistoryRouteNotifierProvider(widget.walkId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: routeAsync.when(
          data: (points) {
            if (points.isEmpty) {
              return const Center(
                child: Text('No locations recorded for this walk.'),
              );
            }
            final bounds = LatLngBounds.fromPoints(points);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _applyBounds(bounds);
            });
            final start = points.first;
            final end = points.last;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Walk ID: ${widget.walkId}'),
                const SizedBox(height: 8),
                Text('Points: ${points.length}'),
                const SizedBox(height: 12),
                Expanded(
                  child: FlutterMap(
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
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.arukuPallarel',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 4,
                            color: Colors.blue,
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
                              color: Colors.green,
                            ),
                          ),
                          Marker(
                            point: end,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('Failed to load route: $error'),
          ),
        ),
      ),
    );
  }
}
