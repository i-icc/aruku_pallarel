import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../widgets/app_location_marker.dart';

class WalkMapLayer extends StatelessWidget {
  const WalkMapLayer({
    super.key,
    required this.mapController,
    required this.center,
    required this.onPositionChanged,
    required this.onMapReady,
    required this.urlTemplate,
    required this.subdomains,
    required this.routePoints,
    required this.suggestMarkers,
    required this.heading,
    this.onMapTap,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  final MapController mapController;
  final LatLng center;
  final PositionCallback onPositionChanged;
  final VoidCallback onMapReady;
  final String urlTemplate;
  final List<String> subdomains;
  final List<LatLng> routePoints;
  final List<Marker> suggestMarkers;
  final double? heading;
  final TapCallback? onMapTap;
  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerCancelEventListener? onPointerCancel;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 16,
          onPositionChanged: onPositionChanged,
          onMapReady: onMapReady,
          onTap: onMapTap,
        ),
        children: [
          TileLayer(
            urlTemplate: urlTemplate,
            subdomains: subdomains,
            userAgentPackageName: 'com.example.arukuPallarel',
          ),
          if (routePoints.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 4,
                  color: const Color(0xFF36FF97).withValues(alpha: 0.8),
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              ...suggestMarkers,
              Marker(
                point: center,
                width: 120,
                height: 120,
                child: AppLocationMarker(
                  heading: heading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
