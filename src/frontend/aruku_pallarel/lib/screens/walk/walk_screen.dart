import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart';

import '../../features/share/services/backend_exception.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/walk_location_recorder_provider.dart';
import '../../features/walk/provider/walk_tracking_provider.dart';

@RoutePage()
class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  static const LatLng _fallbackCenter = LatLng(35.681236, 139.767125);

  bool _finishLoading = false;
  String? _locationError;
  LatLng? _currentCenter;
  bool _mapReady = false;
  StreamSubscription<Location>? _locationSubscription;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _finishWalk() async {
    setState(() {
      _finishLoading = true;
    });

    try {
      await ref.read(activeWalkNotifierProvider.notifier).finishWalk();
      await ref
          .read(walkLocationRecorderNotifierProvider.notifier)
          .stopRecording();
      await ref.read(walkTrackingNotifierProvider.notifier).stopTracking();
      if (!mounted) {
        return;
      }
      context.router.pop();
    } on BackendException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _finishLoading = false;
        });
      }
    }
  }

  Future<void> _startTracking() async {
    final activeWalk = ref.read(activeWalkNotifierProvider);
    if (activeWalk == null) {
      return;
    }

    setState(() {
      _locationError = null;
    });

    final granted =
        await ref.read(walkTrackingNotifierProvider.notifier).startTracking();
    if (!granted) {
      if (mounted) {
        setState(() {
          _locationError = 'Location permission is required.';
        });
      }
      return;
    }

    await ref
        .read(walkLocationRecorderNotifierProvider.notifier)
        .startRecording(activeWalk.walkId);

    await _locationSubscription?.cancel();
    _locationSubscription = Locus.location.stream.listen(
      (location) {
        final coords = location.coords;
        if (!coords.isValid) {
          return;
        }
        final center = LatLng(coords.latitude, coords.longitude);
        if (!mounted) {
          return;
        }
        setState(() {
          _currentCenter = center;
        });
        if (_mapReady) {
          _mapController.move(center, _mapController.camera.zoom);
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _locationError = error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWalk = ref.watch(activeWalkNotifierProvider);
    final trackingState = ref.watch(walkTrackingNotifierProvider);
    final center = _currentCenter ?? _fallbackCenter;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Walk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (activeWalk == null) ...[
              const Text('No active walk.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.router.pop(),
                child: const Text('Back to Home'),
              ),
            ] else ...[
              Text('Walk ID: ${activeWalk.walkId}'),
              if (_locationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _locationError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 12),
              if (!trackingState.permissionGranted) ...[
                Text(
                  trackingState.isRequesting
                      ? 'Requesting location permission...'
                      : 'Location permission is not granted.',
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: trackingState.isRequesting ? null : _startTracking,
                  child: const Text('Enable Location'),
                ),
              ] else ...[
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 16,
                      onMapReady: () {
                        _mapReady = true;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.arukuPallarel',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lat: ${center.latitude.toStringAsFixed(5)}, '
                  'Lon: ${center.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _finishLoading ? null : _finishWalk,
                  child: _finishLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Finish Walk'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
