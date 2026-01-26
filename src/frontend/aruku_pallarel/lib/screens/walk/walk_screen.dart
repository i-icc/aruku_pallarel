import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;
import 'package:url_launcher/url_launcher.dart';

import '../../features/history/provider/walk_history_provider.dart';
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

class _WalkScreenState extends ConsumerState<WalkScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const LatLng _fallbackCenter = LatLng(35.681236, 139.767125);
  static const Duration _spoofHoldDuration = Duration(seconds: 2);
  static const double _spoofMoveThreshold = 12;
  static const Duration _mapMoveDuration = Duration(milliseconds: 600);
  static const int _routeSplineSteps = 8;
  static const double _routeSplineAlpha = 0.5;

  bool _finishLoading = false;
  String? _locationError;
  LatLng? _currentCenter;
  double? _compassHeading;
  double? _movementHeading;
  bool _mapReady = false;
  StreamSubscription<locus.Location>? _locationSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  ProviderSubscription<WalkSession?>? _activeWalkSubscription;
  final MapController _mapController = MapController();
  late final AnimationController _mapMoveController;
  late final AnimationController _headingPulseController;
  LatLng? _mapMoveStart;
  LatLng? _mapMoveTarget;
  double? _mapMoveZoom;
  List<LatLng> _smoothedRoutePoints = [];
  final List<LatLng> _routePoints = [];
  String? _routeWalkId;
  Timer? _spoofTimer;
  Offset? _spoofPressPosition;
  Offset? _spoofStartPosition;
  int? _spoofPointerId;

  @override
  void initState() {
    super.initState();
    _mapMoveController = AnimationController(
      vsync: this,
      duration: _mapMoveDuration,
    )
      ..value = 1.0
      ..addListener(_handleMapMoveTick);
    _headingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startCompass();
    WidgetsBinding.instance.addObserver(this);
    _activeWalkSubscription = ref.listenManual(
      activeWalkNotifierProvider,
      (previous, next) {
        if (next == null || previous?.walkId == next.walkId) {
          return;
        }
        _startTracking();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startTracking();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncStoredLocations());
    }
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

    unawaited(_loadRouteForWalk(activeWalk.walkId));

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
        _recordRoutePoint(spoofState.location!, updateHeading: true);
        _animateMapMove(spoofState.location!);
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

    final lastKnown = await _fetchLastKnownLocation();
    if (lastKnown != null && mounted && _currentCenter == null) {
      _recordRoutePoint(
        lastKnown,
        updateCenter: true,
        updateHeading: true,
      );
      if (_mapReady) {
        _animateMapMove(lastKnown);
      }
    }

    await ref
        .read(walkLocationRecorderNotifierProvider.notifier)
        .startRecording(activeWalk.walkId);
    unawaited(_syncStoredLocations());

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
        _recordRoutePoint(
          center,
          updateCenter: true,
          updateHeading: true,
          heading: coords.heading,
        );
        if (_mapReady) {
          _animateMapMove(center);
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
        _recordRoutePoint(
          center,
          updateCenter: true,
          updateHeading: true,
          heading: coords.heading,
        );
        if (_mapReady) {
          _animateMapMove(center);
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
    _compassSubscription?.cancel();
    _activeWalkSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    _cancelSpoofTimer();
    _mapMoveController.dispose();
    _headingPulseController.dispose();
    super.dispose();
  }

  void _cancelSpoofTimer() {
    _spoofTimer?.cancel();
    _spoofTimer = null;
    _spoofPressPosition = null;
    _spoofStartPosition = null;
    _spoofPointerId = null;
  }

  Future<LatLng?> _fetchLastKnownLocation() async {
    try {
      final debugState = await locus.Locus.getState();
      final location = debugState.location;
      final coords = location?.coords;
      if (coords != null && coords.isValid) {
        return LatLng(coords.latitude, coords.longitude);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _syncStoredLocations() async {
    final activeWalk = ref.read(activeWalkNotifierProvider);
    if (activeWalk == null) {
      return;
    }
    final lastLocation = await ref
        .read(walkLocationRecorderNotifierProvider.notifier)
        .syncStoredLocations();
    if (!mounted || lastLocation == null) {
      return;
    }
    if (!ref.read(locationSpoofNotifierProvider).enabled) {
      _recordRoutePoint(
        lastLocation,
        updateCenter: true,
        updateHeading: true,
      );
      if (_mapReady) {
        _animateMapMove(lastLocation);
      }
    }
    unawaited(_loadRouteForWalk(activeWalk.walkId));
  }

  double _safeZoom({double fallback = 16}) {
    final zoom = _mapController.camera.zoom;
    if (zoom.isFinite) {
      return zoom;
    }
    return fallback;
  }

  void _startCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      return;
    }
    _compassSubscription = stream.listen(
      (event) {
        final heading = _normalizeHeading(event.heading);
        if (!mounted || heading == null) {
          return;
        }
        final previous = _compassHeading;
        if (previous != null && (previous - heading).abs() < 0.5) {
          return;
        }
        setState(() {
          _compassHeading = heading;
        });
      },
      onError: (_) {},
    );
  }

  double? _normalizeHeading(double? heading) {
    if (heading == null || !heading.isFinite) {
      return null;
    }
    var normalized = heading % 360;
    if (normalized < 0) {
      normalized += 360;
    }
    return normalized;
  }

  double _catmullT(double t, LatLng p0, LatLng p1) {
    final dx = p1.latitude - p0.latitude;
    final dy = p1.longitude - p0.longitude;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) {
      return t + 0.000001;
    }
    return t + pow(dist, _routeSplineAlpha).toDouble();
  }

  LatLng _interpolateLatLng(
    LatLng start,
    LatLng end,
    double t0,
    double t1,
    double t,
  ) {
    final span = t1 - t0;
    if (span.abs() < 0.000001) {
      return start;
    }
    return _lerpLatLng(start, end, (t - t0) / span);
  }

  LatLng _catmullRomPoint(
    LatLng p0,
    LatLng p1,
    LatLng p2,
    LatLng p3,
    double t0,
    double t1,
    double t2,
    double t3,
    double t,
  ) {
    final a1 = _interpolateLatLng(p0, p1, t0, t1, t);
    final a2 = _interpolateLatLng(p1, p2, t1, t2, t);
    final a3 = _interpolateLatLng(p2, p3, t2, t3, t);
    final b1 = _interpolateLatLng(a1, a2, t0, t2, t);
    final b2 = _interpolateLatLng(a2, a3, t1, t3, t);
    return _interpolateLatLng(b1, b2, t1, t2, t);
  }

  List<LatLng> _catmullRomSegment(
    LatLng p0,
    LatLng p1,
    LatLng p2,
    LatLng p3,
  ) {
    final t0 = 0.0;
    final t1 = _catmullT(t0, p0, p1);
    final t2 = _catmullT(t1, p1, p2);
    final t3 = _catmullT(t2, p2, p3);
    final segment = <LatLng>[];
    for (var i = 0; i <= _routeSplineSteps; i++) {
      final t = ui.lerpDouble(t1, t2, i / _routeSplineSteps) ?? t1;
      segment.add(_catmullRomPoint(p0, p1, p2, p3, t0, t1, t2, t3, t));
    }
    return segment;
  }

  List<LatLng> _smoothRoutePoints(List<LatLng> points) {
    if (points.length < 2) {
      return List<LatLng>.from(points);
    }
    final smoothed = <LatLng>[];
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];
      final segment = _catmullRomSegment(p0, p1, p2, p3);
      if (smoothed.isNotEmpty && segment.isNotEmpty) {
        segment.removeAt(0);
      }
      smoothed.addAll(segment);
    }
    return smoothed;
  }

  LatLng _lerpLatLng(LatLng start, LatLng target, double t) {
    final lat =
        ui.lerpDouble(start.latitude, target.latitude, t) ?? target.latitude;
    final lng =
        ui.lerpDouble(start.longitude, target.longitude, t) ?? target.longitude;
    return LatLng(lat, lng);
  }

  LatLng _resolveAnimatedCenter(LatLng center) {
    final start = _mapMoveStart;
    final target = _mapMoveTarget;
    if (start == null || target == null) {
      return center;
    }
    if (!_isSamePoint(target, center)) {
      return center;
    }
    final t = Curves.easeInOutCubic.transform(_mapMoveController.value);
    return _lerpLatLng(start, target, t);
  }

  Widget _buildHeadingMarker(double? heading) {
    final normalized = _normalizeHeading(heading);
    return AnimatedBuilder(
      animation: _headingPulseController,
      builder: (context, child) {
        final pulse = Curves.easeOut.transform(_headingPulseController.value);
        final ringSize = ui.lerpDouble(18, 44, pulse) ?? 44;
        final ringOpacity = (1 - pulse) * 0.35;
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: ringOpacity * 0.4),
                  border: Border.all(
                    color:
                        AppColors.accent.withValues(alpha: ringOpacity + 0.05),
                    width: 2,
                  ),
                ),
              ),
              if (normalized != null)
                Transform.rotate(
                  angle: normalized * pi / 180,
                  child: CustomPaint(
                    size: const Size(48, 48),
                    painter: _HeadingConePainter(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: AppShadows.tight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMapMoveTick() {
    if (!_mapReady || _mapMoveStart == null || _mapMoveTarget == null) {
      return;
    }
    final t = Curves.easeInOutCubic.transform(_mapMoveController.value);
    final position = _lerpLatLng(_mapMoveStart!, _mapMoveTarget!, t);
    final targetZoom = _mapMoveZoom ?? _safeZoom();
    _mapController.move(position, targetZoom);
  }

  void _animateMapMove(LatLng target, {double? zoom}) {
    if (!_mapReady) {
      _mapMoveStart = target;
      _mapMoveTarget = target;
      _mapMoveZoom = zoom ?? _safeZoom();
      _mapMoveController.value = 1.0;
      return;
    }
    final targetZoom = zoom ?? _safeZoom();
    final start = _resolveAnimatedCenter(_mapController.camera.center);
    _mapMoveStart = start;
    _mapMoveTarget = target;
    _mapMoveZoom = targetZoom;
    if (_isSamePoint(start, target)) {
      _mapMoveController.value = 1.0;
      _mapController.move(target, targetZoom);
      return;
    }
    _mapMoveController
      ..stop()
      ..value = 0.0
      ..forward();
  }

  void _applyInitialCenter() {
    if (!_mapReady) {
      return;
    }
    final spoofState = ref.read(locationSpoofNotifierProvider);
    final target = spoofState.enabled && spoofState.location != null
        ? spoofState.location
        : (_currentCenter ??
            (_routePoints.isNotEmpty ? _routePoints.last : null));
    if (target == null) {
      return;
    }
    _animateMapMove(target);
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
    _recordRoutePoint(latLng, updateHeading: true);
    _animateMapMove(latLng);
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
        : (_currentCenter ??
            (_routePoints.isNotEmpty ? _routePoints.last : _fallbackCenter));
    final routePoints = _smoothedRoutePoints.isNotEmpty
        ? _smoothedRoutePoints
        : _routePoints;

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
                    _applyInitialCenter();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapTheme.urlTemplate,
                    subdomains: mapTheme.subdomains,
                    userAgentPackageName: 'com.example.arukuPallarel',
                  ),
                  if (routePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4,
                          color: AppColors.accent.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 48,
                        height: 48,
                        child: _buildHeadingMarker(
                          _compassHeading ?? _movementHeading,
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
            right: 0,
            top: 0,
            child: SafeArea(
              left: false,
              bottom: false,
              minimum: const EdgeInsets.only(top: 8, right: 8),
              child: MapInfoButton(
                onTap: () => showMapAttributionSheet(context, mapThemeId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSamePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  void _recordRoutePoint(
    LatLng point, {
    bool updateCenter = false,
    bool updateHeading = false,
    double? heading,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (updateCenter) {
        _currentCenter = point;
      }
      if (updateHeading) {
        final normalized = _normalizeHeading(heading);
        if (normalized != null) {
          _movementHeading = normalized;
        }
      }
      if (_routePoints.isEmpty || !_isSamePoint(_routePoints.last, point)) {
        _routePoints.add(point);
        _smoothedRoutePoints = _smoothRoutePoints(_routePoints);
      }
    });
  }

  Future<void> _loadRouteForWalk(String walkId) async {
    if (_routeWalkId != walkId) {
      if (mounted) {
        setState(() {
          _routeWalkId = walkId;
          _routePoints.clear();
          _smoothedRoutePoints.clear();
        });
      } else {
        _routeWalkId = walkId;
        _routePoints.clear();
        _smoothedRoutePoints.clear();
      }
    }
    try {
      final points =
          await ref.read(walkHistoryRouteNotifierProvider(walkId).future);
      if (!mounted || _routeWalkId != walkId || points.isEmpty) {
        return;
      }
      LatLng? appliedCenter;
      setState(() {
        if (_routePoints.isEmpty) {
          _routePoints.addAll(points);
          _smoothedRoutePoints = _smoothRoutePoints(_routePoints);
          if (_currentCenter == null) {
            _currentCenter = _routePoints.last;
            appliedCenter = _currentCenter;
          }
          return;
        }
        final merged = <LatLng>[...points];
        for (final point in _routePoints) {
          if (merged.isEmpty || !_isSamePoint(merged.last, point)) {
            merged.add(point);
          }
        }
        _routePoints
          ..clear()
          ..addAll(merged);
        _smoothedRoutePoints = _smoothRoutePoints(_routePoints);
        if (_currentCenter == null && _routePoints.isNotEmpty) {
          _currentCenter = _routePoints.last;
          appliedCenter = _currentCenter;
        }
      });
      if (!ref.read(locationSpoofNotifierProvider).enabled &&
          appliedCenter != null &&
          _mapReady) {
        _animateMapMove(appliedCenter!);
      }
    } catch (_) {
      return;
    }
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

class _HeadingConePainter extends CustomPainter {
  const _HeadingConePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sweep = pi / 3;
    final startAngle = -pi / 2 - sweep / 2;
    final path = ui.Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        ui.Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeadingConePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
