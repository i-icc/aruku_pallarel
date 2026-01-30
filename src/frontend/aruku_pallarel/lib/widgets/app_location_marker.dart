import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_styles.dart';

class AppLocationMarker extends StatefulWidget {
  const AppLocationMarker({
    super.key,
    this.heading,
  });

  final double? heading;

  @override
  State<AppLocationMarker> createState() => _AppLocationMarkerState();
}

class _AppLocationMarkerState extends State<AppLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headingPulseController;

  @override
  void initState() {
    super.initState();
    _headingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _headingPulseController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeHeading(widget.heading);
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
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // 波の色は薄めにして、白い輪郭がしっかり見えるように
                  color: const Color(0xFF36FF97)
                      .withValues(alpha: ringOpacity * 0.25),
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
