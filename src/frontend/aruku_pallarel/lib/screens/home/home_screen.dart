import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;

import '../../features/walk/provider/location_spoof_provider.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/walk_tracking_provider.dart';
import '../../features/share/services/backend_exception.dart';
import '../../router/app_router.dart';

import '../../theme/map_tiles.dart';
import '../../theme/map_theme_provider.dart';
import '../../widgets/app_gradient_pill_button.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_floating_button.dart';
import '../../widgets/app_location_marker.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const LatLng _fallbackCenter = LatLng(35.681236, 139.767125);

  final MapController _mapController = MapController();
  bool _walkLoading = false;
  LatLng? _currentCenter;
  bool _showStartConfirm = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(activeWalkNotifierProvider.notifier).loadActiveWalk();
      _fetchInitialLocation();
    });
  }

  Future<void> _fetchInitialLocation() async {
    final spoofState = ref.read(locationSpoofNotifierProvider);
    if (spoofState.enabled && spoofState.location != null) {
      if (mounted) {
        setState(() {
          _currentCenter = spoofState.location;
        });
      }
      return;
    }

    try {
       // Try getting current position first
      final current = await locus.LocusLocation.getCurrentPosition(
        timeout: 5,
        maximumAge: 60, // Allow 1 minute old cache
      );
      final coords = current.coords;
      if (coords.isValid && mounted) {
        setState(() {
          _currentCenter = LatLng(coords.latitude, coords.longitude);
        });
        return;
      }
    } catch (_) {
      // Ignore errors and try fallback
    }

    final lastKnown = await _fetchLastKnownLocation();
    if (lastKnown != null && mounted) {
      setState(() {
        _currentCenter = lastKnown;
      });
    } else if (mounted) {
       setState(() {
        _currentCenter = _fallbackCenter;
      });
    }
  }

  Future<LatLng?> _fetchLastKnownLocation() async {
    try {
      final state = await locus.Locus.getState();
      final location = state.location;
      final coords = location?.coords;
      if (coords != null && coords.isValid) {
        return LatLng(coords.latitude, coords.longitude);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _startWalk() async {
    setState(() {
      _walkLoading = true;
    });

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
             final current = await locus.LocusLocation.getCurrentPosition(timeout: 10)
                 .timeout(const Duration(seconds: 60));
             final coords = current.coords;
             if (coords.isValid) {
                 startLocation = LatLng(coords.latitude, coords.longitude);
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
      await context.router.push(const WalkRoute());

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
           if (_currentCenter != null)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter!,
                  initialZoom: 16,
                  onMapReady: () {},
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapTheme.urlTemplate,
                    subdomains: mapTheme.subdomains,
                    userAgentPackageName: 'com.example.arukuPallarel',
                  ),
                  // Current location marker could be added here if we have a stream,
                  // but for the home screen, maybe just a static map center or simple marker is enough for now?
                  // The Plan said "FlutterMap implementation similar to WalkScreen (displaying current location)".
                  // I'll add a simple marker at the center if we have location.
                   MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentCenter!,
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // History Button
                    AppFloatingButton(
                      icon: Icons.history,
                      onTap: () => context.router.push(const HistoryRoute()),
                    ),
                    const SizedBox(width: 16),
                    // Start/Continue Button
                    Expanded(
                      child: SizedBox(
                        height: 56, // Match floating button height roughly or define specific height
                        // Walk finish button in dialog used 54. Let's use 56 to match floating button size.
                        child: AppGradientPillButton(
                          label: buttonLabel,
                          isLoading: _walkLoading,
                          height: 56,
                          onPressed: () {
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
                    const SizedBox(width: 16),
                    // Settings Button
                    AppFloatingButton(
                      icon: Icons.settings,
                      onTap: () {
                         showModalBottomSheet(
                           context: context,
                           isScrollControlled: true,
                           backgroundColor: Colors.transparent,
                           builder: (_) => const SettingsSheet(),
                         );
                      },
                    ),
                  ],
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
                  description: '位置情報を利用して移動距離を記録します',
                  confirmLabel: '散歩を始める',
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
