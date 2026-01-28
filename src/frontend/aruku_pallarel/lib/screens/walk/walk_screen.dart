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


import '../../features/history/provider/walk_history_provider.dart';
import '../../features/share/services/backend_exception.dart';
import '../../features/walk/models/walk_session.dart';
import '../../features/walk/models/walk_suggest.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/location_spoof_provider.dart';
import '../../features/walk/provider/walk_suggestion_provider.dart';
import '../../features/walk/provider/walk_location_recorder_provider.dart';
import '../../features/walk/provider/walk_tracking_provider.dart';
import '../../theme/app_styles.dart';
import '../../theme/map_tiles.dart';
import '../../theme/map_theme_provider.dart';

import '../../widgets/app_gradient_pill_button.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_floating_button.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';
import '../../router/app_router.dart';

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
  ProviderSubscription<SelectedSuggestState>? _selectedSuggestSubscription;
  final MapController _mapController = MapController();
  late final AnimationController _mapMoveController;
  late final AnimationController _headingPulseController;
  LatLng? _mapMoveStart;
  LatLng? _mapMoveTarget;
  double? _mapMoveZoom;
  List<LatLng> _smoothedRoutePoints = [];
  final List<LatLng> _routePoints = [];
  String? _routeWalkId;
  List<WalkSuggest> _latestSuggests = const [];
  DateTime? _lastMapGestureAt;
  String? _lastFocusedSuggestId;
  Timer? _spoofTimer;
  Offset? _spoofPressPosition;
  Offset? _spoofStartPosition;
  int? _spoofPointerId;
  Timer? _elapsedTimer;
  bool _showFinishConfirm = false;

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
    _selectedSuggestSubscription = ref.listenManual(
      selectedSuggestNotifierProvider,
      (previous, next) {
        final walkId = ref.read(activeWalkNotifierProvider)?.walkId;
        if (walkId == null || next.walkId != walkId) {
          return;
        }
        final nextId = next.suggestId;
        if (nextId == null || nextId == previous?.suggestId) {
          return;
        }
        _focusSelectedSuggest(nextId);
      },
    );
    _startCompass();
    WidgetsBinding.instance.addObserver(this);
    _activeWalkSubscription = ref.listenManual(
      activeWalkNotifierProvider,
      (previous, next) {
        if (next == null) {
          _latestSuggests = const [];
          _lastFocusedSuggestId = null;
          return;
        }
        if (previous?.walkId == next.walkId) {
          return;
        }
        _latestSuggests = const [];
        _lastFocusedSuggestId = null;
        _startTracking();
      },
    );
    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {});
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
    _selectedSuggestSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    _cancelSpoofTimer();
    _elapsedTimer?.cancel();
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

  void _noteMapGesture() {
    _lastMapGestureAt = DateTime.now();
  }

  bool _shouldAutoFocusSuggest() {
    if (!_mapReady) {
      return false;
    }
    final lastGesture = _lastMapGestureAt;
    if (lastGesture == null) {
      return true;
    }
    return DateTime.now().difference(lastGesture) >
        const Duration(seconds: 2);
  }

  WalkSuggest? _findSuggestById(String suggestId) {
    for (final suggest in _latestSuggests) {
      if (suggest.suggestId == suggestId) {
        return suggest;
      }
    }
    return null;
  }

  void _focusSelectedSuggest(String suggestId) {
    if (_lastFocusedSuggestId == suggestId) {
      return;
    }
    final target = _findSuggestById(suggestId);
    if (target == null) {
      return;
    }
    if (!_shouldAutoFocusSuggest()) {
      return;
    }
    _animateMapMove(target.position);
    _lastFocusedSuggestId = suggestId;
  }

  void _maybeSelectLatestSuggest(String walkId, List<WalkSuggest> suggests) {
    if (suggests.isEmpty) {
      return;
    }
    final selected = ref.read(selectedSuggestNotifierProvider);
    if (selected.walkId == walkId && selected.suggestId != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final current = ref.read(selectedSuggestNotifierProvider);
      if (current.walkId == walkId && current.suggestId != null) {
        return;
      }
      ref
          .read(selectedSuggestNotifierProvider.notifier)
          .select(walkId, suggests.first.suggestId);
    });
  }

  List<Marker> _buildSuggestMarkers({
    required List<WalkSuggest> suggests,
    required String? walkId,
    required String? selectedSuggestId,
  }) {
    if (walkId == null) {
      return const [];
    }
    return suggests
        .map(
          (suggest) => Marker(
            point: suggest.position,
            width: 46,
            height: 46,
            child: _SuggestPin(
              isSelected: suggest.suggestId == selectedSuggestId,
              onTap: () {
                ref
                    .read(selectedSuggestNotifierProvider.notifier)
                    .select(walkId, suggest.suggestId);
              },
            ),
          ),
        )
        .toList();
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
        // 元の 18–44px をベースに、白と色の比率はほぼそのままに 2.5倍相当へ拡大
        final ringSize = ui.lerpDouble(45, 120, pulse) ?? 120;
        final ringOpacity = (1 - pulse) * 0.35;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 足元にごく薄い影だけを落とす（本体は暗くしない）
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 70,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // 波の色は薄めにして、白い輪郭がしっかり見えるように
                  color:
                      const Color(0xFF36FF97).withValues(alpha: ringOpacity * 0.25),
                  border: Border.all(
                    // 枠線は 2px → 約2.5倍の 5px で白の存在感をキープ
                    color: Colors.white.withValues(alpha: ringOpacity + 0.05),
                    width: 5,
                  ),
                ),
              ),
              if (normalized != null)
                Transform.rotate(
                  angle: normalized * pi / 180,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _HeadingConePainter(
                      color: const Color(0xFF36FF97).withValues(alpha: 0.2),
                    ),
                  ),
                ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF36FF97),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 5.5,
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



  @override
  Widget build(BuildContext context) {
    final activeWalk = ref.watch(activeWalkNotifierProvider);
    final trackingState = ref.watch(walkTrackingNotifierProvider);
    final spoofState = ref.watch(locationSpoofNotifierProvider);
    final walkId = activeWalk?.walkId;
    final suggestsAsync = walkId == null
        ? const AsyncValue.data(<WalkSuggest>[])
        : ref.watch(walkSuggestListProvider(walkId));
    final selectedSuggestState = ref.watch(selectedSuggestNotifierProvider);
    final selectedSuggestId =
        selectedSuggestState.walkId == walkId ? selectedSuggestState.suggestId : null;
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
    final distanceKm = _calculateRouteDistanceKm(routePoints);
    final elapsedMinutes = _calculateElapsedMinutes(activeWalk);

    final notices = _buildNotices(
      spoofState: spoofState,
      trackingState: trackingState,
    );

    final mainButtonState = _resolveMainButtonState(
      context: context,
      activeWalk: activeWalk,
      spoofEnabled: spoofEnabled,
      trackingState: trackingState,
    );

    final suggestMarkers = suggestsAsync.when(
      data: (suggests) {
        _latestSuggests = suggests;
        if (walkId != null) {
          _maybeSelectLatestSuggest(walkId, suggests);
        }
        if (selectedSuggestId != null &&
            _lastFocusedSuggestId != selectedSuggestId &&
            _findSuggestById(selectedSuggestId) != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _focusSelectedSuggest(selectedSuggestId);
          });
        }
        return _buildSuggestMarkers(
          suggests: suggests,
          walkId: walkId,
          selectedSuggestId: selectedSuggestId,
        );
      },
      loading: () => const <Marker>[],
      error: (error, stackTrace) => const <Marker>[],
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                // マップ用: エッジがはっきりした短めの影
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000), // やや強めの影
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                      onPositionChanged: (_, hasGesture) {
                        if (hasGesture) {
                          _noteMapGesture();
                        }
                      },
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
                              color:
                                  const Color(0xFF36FF97).withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          ...suggestMarkers,
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
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            child: SafeArea(
              bottom: false,
              child: _WalkInfoHeader(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notices.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: notices,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.55,
                      child: AppGradientPillButton(
                        label: mainButtonState.label,
                        isLoading: mainButtonState.isLoading,
                        onPressed: mainButtonState.onPressed,
                      ),
                    ),
                  ),
                ],
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
                onTap: () => context.router.push(const ChatRoute()),
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
          if (_showFinishConfirm) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showFinishConfirm = false;
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
                  title: '散歩を終わりますか？',
                  description: '※歩きスマホにご注意ください',
                  confirmLabel: 'おわる',
                  cancelLabel: 'もどる',
                  onCancel: () {
                    setState(() {
                      _showFinishConfirm = false;
                    });
                  },
                  onConfirm: () {
                    setState(() {
                      _showFinishConfirm = false;
                    });
                    _finishWalk();
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isSamePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  double? _calculateRouteDistanceKm(List<LatLng> points) {
    if (points.length < 2) {
      return null;
    }
    const earthRadius = 6371000.0; // meters
    double totalMeters = 0;
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dLat = _degreesToRadians(p2.latitude - p1.latitude);
      final dLon = _degreesToRadians(p2.longitude - p1.longitude);
      final lat1Rad = _degreesToRadians(p1.latitude);
      final lat2Rad = _degreesToRadians(p2.latitude);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * asin(sqrt(a));
      totalMeters += earthRadius * c;
    }
    if (totalMeters <= 0) {
      return null;
    }
    return totalMeters / 1000.0;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  int? _calculateElapsedMinutes(WalkSession? session) {
    final startedAt = session?.startedAt;
    if (startedAt == null) {
      return null;
    }
    final start = DateTime.tryParse(startedAt);
    if (start == null) {
      return null;
    }
    final now = DateTime.now();
    final diff = now.difference(start);
    if (diff.isNegative) {
      return 0;
    }
    return diff.inMinutes;
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

  _MainButtonState _resolveMainButtonState({
    required BuildContext context,
    required WalkSession? activeWalk,
    required bool spoofEnabled,
    required WalkTrackingState trackingState,
  }) {
    // 位置情報がまだ許可されていない場合
    if (!trackingState.permissionGranted && !spoofEnabled) {
      final label = trackingState.isRequesting
          ? '位置情報をリクエスト中...'
          : '位置情報を有効にする';
      return _MainButtonState(
        label: label,
        isLoading: trackingState.isRequesting,
        onPressed: trackingState.isRequesting ? null : _startTracking,
      );
    }

    // 散歩セッションが存在しない場合
    if (activeWalk == null) {
      return _MainButtonState(
        label: 'ホームに戻る',
        isLoading: false,
        onPressed: () => context.router.pop(),
      );
    }

    // 散歩中の場合
    return _MainButtonState(
      label: '散歩を終わる',
      isLoading: _finishLoading,
      onPressed: _finishLoading
          ? null
          : () {
              setState(() {
                _showFinishConfirm = true;
              });
            },
    );
  }
}

class _MainButtonState {
  const _MainButtonState({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
}

class _WalkInfoHeader extends StatelessWidget {
  const _WalkInfoHeader({
    required this.distanceKm,
    required this.elapsedMinutes,
  });

  final double? distanceKm;
  final int? elapsedMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme.titleMedium;
    final scaledFontSize =
        (baseTextStyle?.fontSize != null ? baseTextStyle!.fontSize! * 1.2 : 19.0);
    const iconColor = Colors.grey;
    final distanceText =
        distanceKm == null ? '-- km' : '${distanceKm!.toStringAsFixed(1)}km';
    final minutesText =
        elapsedMinutes == null ? '--分' : '${elapsedMinutes!.toString()}分';

    return Align(
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        widthFactor: 0.9, // 横幅を 0.9 倍に
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), // 縦幅を少しだけ増やす（約 1.1 倍）
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // 完全な白
            borderRadius: BorderRadius.circular(5), // 角丸をさらに控えめに
            // カード用: エッジが際立つ、短く落ちる影
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      color: iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      distanceText,
                      style: baseTextStyle?.copyWith(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      minutesText,
                      style: baseTextStyle?.copyWith(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            fontSize: scaledFontSize,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _SuggestPin extends StatelessWidget {
  const _SuggestPin({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pinColor = isSelected ? AppColors.accentWarm : AppColors.accent;
    final ringColor = isSelected
        ? AppColors.accentWarm.withValues(alpha: 0.2)
        : Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.0 : 0.88,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pinColor,
              boxShadow: isSelected ? AppShadows.tight : AppShadows.soft,
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: pinColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: ringColor,
                    blurRadius: 10,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
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
