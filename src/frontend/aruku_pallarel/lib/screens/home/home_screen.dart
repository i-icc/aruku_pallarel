import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../../features/walk/provider/location_spoof_provider.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/walk_tracking_provider.dart';
import '../../features/walk/services/location_service.dart';
import '../../features/share/services/backend_exception.dart';
import '../../features/share/provider/overlay_loading_provider.dart';
import '../../router/app_router.dart';

import '../../theme/map_tiles.dart';
import '../../theme/map_theme_provider.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_location_marker.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';
import '../../widgets/history_sheet.dart';
import 'widgets/home_bottom_actions.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const LatLng _fallbackCenter = LatLng(35.681236, 139.767125);
  static const double _homeZoom = 16.3;

  final MapController _mapController = MapController();
  bool _walkLoading = false;
  LatLng? _currentCenter;
  bool _showStartConfirm = false;
  bool _mapReady = false;
  StreamSubscription<LocationData>? _locationSubscription;
  ProviderSubscription<LocationSpoofState>? _spoofSubscription;


  @override
  void initState() {
    super.initState();
    _spoofSubscription = ref.listenManual(
      locationSpoofNotifierProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        if (next.enabled) {
          _stopLocationUpdates();
          final spoofLocation = next.location;
          if (spoofLocation != null) {
            _updateCenter(spoofLocation);
          }
          return;
        }
        if (previous?.enabled == true && !next.enabled) {
          unawaited(_startLocationUpdates());
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(activeWalkNotifierProvider.notifier).loadActiveWalk();
      unawaited(_fetchInitialLocation());
      unawaited(_startLocationUpdates());
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _spoofSubscription?.close();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialLocation() async {
    final spoofState = ref.read(locationSpoofNotifierProvider);
    if (spoofState.enabled && spoofState.location != null) {
      _updateCenter(spoofState.location!);
      return;
    }

    try {
      final service = ref.read(locationServiceProvider);
      final current =
          await service.getCurrent(timeout: const Duration(seconds: 5));
      final lat = current?.latitude;
      final lon = current?.longitude;
      if (lat != null && lon != null) {
        _updateCenter(LatLng(lat, lon));
        return;
      }
    } catch (_) {
      // Ignore errors and try fallback
    }

    final lastKnown = await _fetchLastKnownLocation();
    if (lastKnown != null) {
      _updateCenter(lastKnown);
    } else {
      _updateCenter(_fallbackCenter);
    }
  }

  Future<LatLng?> _fetchLastKnownLocation() async {
    try {
      final location = ref.read(locationServiceProvider).lastLocation;
      final lat = location?.latitude;
      final lon = location?.longitude;
      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _startLocationUpdates() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    final spoofState = ref.read(locationSpoofNotifierProvider);
    if (spoofState.enabled) {
      if (spoofState.location != null) {
        _updateCenter(spoofState.location!);
      }
      return;
    }

    try {
      final locationService = ref.read(locationServiceProvider);
      final permission = await locationService.ensurePermission();
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        return;
      }
      final serviceEnabled = await locationService.ensureServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      await locationService.configure(
        distanceFilterMeters: 15,
        accuracy: LocationAccuracy.balanced,
      );
      _locationSubscription = locationService.stream.listen((location) {
        final lat = location.latitude;
        final lon = location.longitude;
        if (lat == null || lon == null) {
          return;
        }
        _updateCenter(LatLng(lat, lon));
      });

      final current =
          await locationService.getCurrent(timeout: const Duration(seconds: 5));
      final lat = current?.latitude;
      final lon = current?.longitude;
      if (lat != null && lon != null) {
        _updateCenter(LatLng(lat, lon));
      }
    } catch (_) {
      // Ignore errors
    }
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _updateCenter(LatLng center) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentCenter = center;
    });
    if (_mapReady) {
      _mapController.move(center, _safeZoom());
    }
  }

  double _safeZoom({double fallback = _homeZoom}) {
    final zoom = _mapController.camera.zoom;
    if (zoom.isFinite) {
      return zoom;
    }
    return fallback;
  }

  Future<void> _startWalk() async {
    setState(() {
      _walkLoading = true;
    });
    ref.read(overlayLoadingProvider.notifier).state = true;

    final trackingNotifier = ref.read(walkTrackingNotifierProvider.notifier);
    final wasTracking = ref.read(walkTrackingNotifierProvider).isTracking;
    var stopTrackingOnFailure = false;
    var navigated = false;
    try {
      final spoofState = ref.read(locationSpoofNotifierProvider);
      final spoofLocation = spoofState.enabled ? spoofState.location : null;
      LatLng? startLocation = spoofLocation;

      if (startLocation == null) {
         bool granted = false;
         try {
             granted = await trackingNotifier.startTracking().timeout(const Duration(seconds: 10));
         } catch (_) {}

         if (!granted) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Location permission is required.')),
               );
            }
            return;
         }
         stopTrackingOnFailure = !wasTracking;

         try {
             // Added a secondary timeout at the Dart level to prevent native hang from blocking the UI
             final current = await ref
                 .read(locationServiceProvider)
                 .getCurrent(timeout: const Duration(seconds: 10))
                 .timeout(const Duration(seconds: 60));
             final lat = current?.latitude;
             final lon = current?.longitude;
             if (lat != null && lon != null) {
                 startLocation = LatLng(lat, lon);
             }
         } catch (_) {
             startLocation = await _fetchLastKnownLocation();
         }
      }

      startLocation ??= _fallbackCenter;

      if (!mounted) return;
      
      // Actual API call
      await ref.read(activeWalkNotifierProvider.notifier).startWalk(
        lat: startLocation.latitude,
        lon: startLocation.longitude,
      );
      
      if (!mounted) return;
      navigated = true;
      unawaited(context.router.push(const WalkRoute()));

    } on BackendException catch (error) {
       if (!mounted) return;
       if (error.code == 'WALK_ALREADY_ACTIVE') {
          await context.router.push(const WalkRoute());
       } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
       }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting walk: $e')));
       }
    } finally {
        ref.read(overlayLoadingProvider.notifier).state = false;
        if (mounted) {
            setState(() {
                _walkLoading = false;
            });
        }
        if (!navigated && stopTrackingOnFailure) {
            try {
                // Cleanup in background so a hang here doesn't block UI state update
                trackingNotifier.stopTracking();
            } catch (_) {}
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeWalk = ref.watch(activeWalkNotifierProvider);
    final mapThemeId = ref.watch(mapThemeNotifierProvider);
    final mapTheme = mapThemeId.theme;
    final center = _currentCenter ?? _fallbackCenter;
    
    // If active walk exists, change button label? Or just "Continue"? 
    // Spec says "Sanpo suru" button. If walk is active, maybe it should just go to the screen.
    // The previous implementation had "Continue Walk".
    // I will use "Start Walk" (Sanpo suru) logic, but if active, it will just navigate.
    // Label should probably be "Sanpo suru" (Start Walk) or "Sanpo fukki" (Return to Walk).
    // For now I'll stick to "散歩する" as requested, but maybe "散歩に戻る" if active?
    // User request: "散歩する button, same as finish button widget"
    final buttonLabel = activeWalk == null ? '散歩する' : '散歩に戻る';

    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _homeZoom,
                onMapReady: () {
                  _mapReady = true;
                  if (_currentCenter != null) {
                    _mapController.move(_currentCenter!, _safeZoom());
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTheme.urlTemplate,
                  subdomains: mapTheme.subdomains,
                  userAgentPackageName: 'com.example.arukuPallarel',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 120,
                      height: 120,
                      child: const AppLocationMarker(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Map Attribution
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

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: HomeBottomActions(
                    startWalkLabel: buttonLabel,
                    isStartWalkLoading: false,
                    onHistoryTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const HistorySheet(),
                      );
                    },
                    onSettingsTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SettingsSheet(),
                      );
                    },
                    onStartWalkTap: _walkLoading
                        ? null
                        : () {
                            if (activeWalk != null) {
                              context.router.push(const WalkRoute());
                              return;
                            }
                            setState(() {
                              _showStartConfirm = true;
                            });
                          },
                  ),
              ),
            ),
          ),
          if (_showStartConfirm) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showStartConfirm = false;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Center(
              child: SafeArea(
                child: AppConfirmDialog(
                  title: '散歩を始めますか？',
                  description: '※歩きスマホにご注意ください',
                  confirmLabel: 'はじめる',
                  cancelLabel: 'もどる',
                  onCancel: () {
                    setState(() {
                      _showStartConfirm = false;
                    });
                  },
                  onConfirm: () {
                    setState(() {
                      _showStartConfirm = false;
                    });
                    _startWalk();
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
