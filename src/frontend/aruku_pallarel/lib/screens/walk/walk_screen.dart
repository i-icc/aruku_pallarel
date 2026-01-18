import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;
import 'package:url_launcher/url_launcher.dart';

import '../../features/share/services/backend_exception.dart';
import '../../features/walk/models/walk_session.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/location_spoof_provider.dart';
import '../../features/walk/provider/walk_location_recorder_provider.dart';
import '../../features/walk/provider/walk_tracking_provider.dart';
import '../../theme/app_styles.dart';
import '../../theme/map_tiles.dart';
import '../../theme/map_theme_provider.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';

@RoutePage()
class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  static const LatLng _fallbackCenter = LatLng(35.681236, 139.767125);
  static const Duration _spoofHoldDuration = Duration(seconds: 2);
  static const double _spoofMoveThreshold = 12;

  bool _finishLoading = false;
  String? _locationError;
  LatLng? _currentCenter;
  bool _mapReady = false;
  StreamSubscription<locus.Location>? _locationSubscription;
  final MapController _mapController = MapController();
  Timer? _spoofTimer;
  Offset? _spoofPressPosition;
  Offset? _spoofStartPosition;
  int? _spoofPointerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startTracking();
    });
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

    final spoofState = ref.read(locationSpoofNotifierProvider);
    if (spoofState.enabled) {
      await ref
          .read(walkLocationRecorderNotifierProvider.notifier)
          .startRecording(activeWalk.walkId);
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      if (_mapReady && spoofState.location != null) {
        _mapController.move(
          spoofState.location!,
          _mapController.camera.zoom,
        );
      }
      return;
    }

    final granted =
        await ref.read(walkTrackingNotifierProvider.notifier).startTracking();
    await ref.read(walkTrackingNotifierProvider.notifier).refreshDebugState();
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
    _locationSubscription = locus.Locus.location.stream.listen(
      (location) {
        if (ref.read(locationSpoofNotifierProvider).enabled) {
          return;
        }
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

    try {
      final current = await locus.LocusLocation.getCurrentPosition(
        timeout: 15,
        maximumAge: 0,
      );
      final coords = current.coords;
      if (coords.isValid && mounted) {
        final center = LatLng(coords.latitude, coords.longitude);
        setState(() {
          _currentCenter = center;
        });
        if (_mapReady) {
          _mapController.move(center, _mapController.camera.zoom);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _locationError = 'getCurrentPosition failed: $error';
        });
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _cancelSpoofTimer();
    super.dispose();
  }

  void _cancelSpoofTimer() {
    _spoofTimer?.cancel();
    _spoofTimer = null;
    _spoofPressPosition = null;
    _spoofStartPosition = null;
    _spoofPointerId = null;
  }

  void _onSpoofPointerDown(PointerDownEvent event) {
    if (!ref.read(locationSpoofNotifierProvider).enabled) {
      return;
    }
    _spoofPointerId = event.pointer;
    _spoofPressPosition = event.localPosition;
    _spoofStartPosition = event.localPosition;
    _spoofTimer?.cancel();
    _spoofTimer = Timer(_spoofHoldDuration, _handleSpoofLongPress);
  }

  void _onSpoofPointerMove(PointerMoveEvent event) {
    if (_spoofPointerId != event.pointer || _spoofStartPosition == null) {
      return;
    }
    final delta = event.localPosition - _spoofStartPosition!;
    if (delta.distance > _spoofMoveThreshold) {
      _cancelSpoofTimer();
      return;
    }
    _spoofPressPosition = event.localPosition;
  }

  void _onSpoofPointerUp(PointerUpEvent event) {
    if (_spoofPointerId != event.pointer) {
      return;
    }
    _cancelSpoofTimer();
  }

  void _onSpoofPointerCancel(PointerCancelEvent event) {
    if (_spoofPointerId != event.pointer) {
      return;
    }
    _cancelSpoofTimer();
  }

  void _handleSpoofLongPress() {
    _spoofTimer = null;
    final position = _spoofPressPosition;
    if (!mounted || position == null) {
      return;
    }
    final spoofState = ref.read(locationSpoofNotifierProvider);
    if (!spoofState.enabled || !_mapReady) {
      return;
    }
    final latLng = _mapController.camera.pointToLatLng(
      Point<double>(position.dx, position.dy),
    );
    ref.read(locationSpoofNotifierProvider.notifier).setLocation(latLng);
    ref
        .read(walkLocationRecorderNotifierProvider.notifier)
        .recordManualLocation(latLng);
    _mapController.move(latLng, _mapController.camera.zoom);
  }

  Future<void> _openSettings() async {
    final uri = Uri.parse('app-settings:');
    if (!await launchUrl(uri)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeWalk = ref.watch(activeWalkNotifierProvider);
    final trackingState = ref.watch(walkTrackingNotifierProvider);
    final spoofState = ref.watch(locationSpoofNotifierProvider);
    final mapThemeId = ref.watch(mapThemeNotifierProvider);
    final mapTheme = mapThemeId.theme;
    final spoofEnabled = spoofState.enabled;
    final center = spoofEnabled && spoofState.location != null
        ? spoofState.location!
        : (_currentCenter ?? _fallbackCenter);

    final title = activeWalk == null ? 'No active walk' : 'Live walk';
    final subtitle = activeWalk == null
        ? 'Return to Home to start a session.'
        : 'ID: ${activeWalk.walkId}';

    final notices = _buildNotices(
      spoofState: spoofState,
      trackingState: trackingState,
    );

    final actions = _buildActions(
      context,
      activeWalk: activeWalk,
      spoofEnabled: spoofEnabled,
      trackingState: trackingState,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: spoofEnabled ? _onSpoofPointerDown : null,
              onPointerMove: spoofEnabled ? _onSpoofPointerMove : null,
              onPointerUp: spoofEnabled ? _onSpoofPointerUp : null,
              onPointerCancel: spoofEnabled ? _onSpoofPointerCancel : null,
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
                    urlTemplate: mapTheme.urlTemplate,
                    subdomains: mapTheme.subdomains,
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
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: _BottomPanel(
                title: title,
                subtitle: subtitle,
                notices: notices,
                actions: actions,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: MapInfoButton(
                onTap: () => showMapAttributionSheet(context, mapThemeId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotices({
    required LocationSpoofState spoofState,
    required WalkTrackingState trackingState,
  }) {
    final notices = <Widget>[];

    void addNotice(String text, Color color) {
      notices.add(_Notice(text: text, color: color));
    }

    if (!spoofState.enabled && !trackingState.permissionGranted) {
      addNotice('Location permission is required.', AppColors.warning);
    }
    if (!spoofState.enabled && trackingState.serviceEnabled == false) {
      addNotice(
        'Location services are disabled. Enable them in Settings.',
        AppColors.warning,
      );
    }
    if (!spoofState.enabled &&
        trackingState.permissionGranted &&
        trackingState.alwaysGranted == false) {
      addNotice(
        'Background location is not granted. Tracking may stop.',
        AppColors.warning,
      );
    }
    if (!spoofState.enabled && _currentCenter == null) {
      addNotice('Waiting for location updates...', AppColors.inkMuted);
    }
    if (spoofState.enabled) {
      addNotice(
        spoofState.location == null
            ? 'Mock mode: hold 2s on the map to set your location.'
            : 'Mock mode is active.',
        AppColors.accentCool,
      );
    }
    if (_locationError != null && !spoofState.enabled) {
      addNotice(_locationError!, AppColors.danger);
    }

    return notices
        .map(
          (notice) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: notice,
          ),
        )
        .toList();
  }

  List<Widget> _buildActions(
    BuildContext context, {
    required WalkSession? activeWalk,
    required bool spoofEnabled,
    required WalkTrackingState trackingState,
  }) {
    final actions = <Widget>[];

    if (!trackingState.permissionGranted && !spoofEnabled) {
      actions.add(
        AppPrimaryButton(
          label: trackingState.isRequesting
              ? 'Requesting Location'
              : 'Enable Location',
          icon: Icons.my_location,
          isLoading: trackingState.isRequesting,
          onPressed: trackingState.isRequesting ? null : _startTracking,
        ),
      );
      actions.add(const SizedBox(height: 8));
      actions.add(
        OutlinedButton(
          onPressed: _openSettings,
          child: const Text('Open Settings'),
        ),
      );
      return actions;
    }

    if (activeWalk == null) {
      actions.add(
        AppPrimaryButton(
          label: 'Back to Home',
          icon: Icons.home_outlined,
          onPressed: () => context.router.pop(),
        ),
      );
    } else {
      actions.add(
        AppPrimaryButton(
          label: 'Finish Walk',
          icon: Icons.stop_circle_outlined,
          isLoading: _finishLoading,
          backgroundColor: AppColors.danger,
          onPressed: _finishLoading ? null : _finishWalk,
        ),
      );
    }

    return actions;
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.title,
    required this.subtitle,
    required this.notices,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> notices;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
          if (notices.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...notices,
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...actions,
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
      ),
    );
  }
}
