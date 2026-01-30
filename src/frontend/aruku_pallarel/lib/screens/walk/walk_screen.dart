import 'dart:async';
import 'dart:math';


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
import '../../features/share/provider/overlay_loading_provider.dart';
import '../../theme/app_styles.dart';
import '../../theme/map_tiles.dart';
import '../../theme/map_theme_provider.dart';


import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_floating_button.dart';
import '../../widgets/map_attribution_sheet.dart';
import '../../widgets/map_info_button.dart';

import '../../router/app_router.dart';
import '../../features/walk/utils/map_utils.dart';
import '../../features/walk/utils/route_smoother.dart';
import 'widgets/walk_info_header.dart';
import 'widgets/walk_notice.dart';
import 'widgets/walk_suggest_pin.dart';
import 'widgets/walk_map_layer.dart';
import 'widgets/walk_bottom_overlay.dart';

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
    ref.read(overlayLoadingProvider.notifier).state = true;

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
      ref.read(overlayLoadingProvider.notifier).state = false;
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
            child: WalkSuggestPin(
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





  LatLng _resolveAnimatedCenter(LatLng center) {
    final start = _mapMoveStart;
    final target = _mapMoveTarget;
    if (start == null || target == null) {
      return center;
    }
    if (!MapUtils.isSamePoint(target, center)) {
      return center;
    }
    final t = Curves.easeInOutCubic.transform(_mapMoveController.value);
    return RouteSmoother.lerpLatLng(start, target, t);
  }

  void _handleMapMoveTick() {
    if (!_mapReady || _mapMoveStart == null || _mapMoveTarget == null) {
      return;
    }
    final t = Curves.easeInOutCubic.transform(_mapMoveController.value);
    final position = RouteSmoother.lerpLatLng(_mapMoveStart!, _mapMoveTarget!, t);
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
    if (MapUtils.isSamePoint(start, target)) {
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
    final distanceKm = MapUtils.calculateRouteDistanceKm(routePoints);
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
                child: WalkMapLayer(
                  mapController: _mapController,
                  center: center,
                  onPositionChanged: (_, hasGesture) {
                    if (hasGesture) {
                      _noteMapGesture();
                    }
                  },
                  onMapReady: () {
                    _mapReady = true;
                    _applyInitialCenter();
                  },
                  urlTemplate: mapTheme.urlTemplate,
                  subdomains: mapTheme.subdomains,
                  routePoints: routePoints,
                  suggestMarkers: suggestMarkers,
                  heading: _compassHeading ?? _movementHeading,
                  onPointerDown: spoofEnabled ? _onSpoofPointerDown : null,
                  onPointerMove: spoofEnabled ? _onSpoofPointerMove : null,
                  onPointerUp: spoofEnabled ? _onSpoofPointerUp : null,
                  onPointerCancel: spoofEnabled ? _onSpoofPointerCancel : null,
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
                  mainButtonLabel: mainButtonState.label,
                  isMainButtonLoading: mainButtonState.isLoading,
                  isMainButtonDestructive: mainButtonState.isDestructive,
                  onMainButtonPressed: mainButtonState.onPressed,
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
      if (_routePoints.isEmpty || !MapUtils.isSamePoint(_routePoints.last, point)) {
        _routePoints.add(point);
        _smoothedRoutePoints = RouteSmoother.smooth(_routePoints);
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
          _smoothedRoutePoints = RouteSmoother.smooth(_routePoints);
          if (_currentCenter == null) {
            _currentCenter = _routePoints.last;
            appliedCenter = _currentCenter;
          }
          return;
        }
        final merged = <LatLng>[...points];
        for (final point in _routePoints) {
          if (merged.isEmpty || !MapUtils.isSamePoint(merged.last, point)) {
            merged.add(point);
          }
        }
        _routePoints
          ..clear()
          ..addAll(merged);
        _smoothedRoutePoints = RouteSmoother.smooth(_routePoints);
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
      notices.add(WalkNotice(text: text, color: color));
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
        isDestructive: false,
        onPressed: trackingState.isRequesting ? null : _startTracking,
      );
    }

    // 散歩セッションが存在しない場合
    if (activeWalk == null) {
      return _MainButtonState(
        label: 'ホームに戻る',
        isLoading: false,
        isDestructive: true,
        onPressed: () => context.router.pop(),
      );
    }

    // 散歩中の場合
    return _MainButtonState(
      label: '散歩を終わる',
      isLoading: false,
      isDestructive: true,
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
    required this.isDestructive,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final bool isDestructive;
  final VoidCallback? onPressed;
}


