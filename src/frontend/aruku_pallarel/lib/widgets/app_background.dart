import 'package:flutter/material.dart';

import '../theme/app_styles.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.applySafeArea = true,
    this.padding,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final Widget child;
  final bool applySafeArea;
  final EdgeInsetsGeometry? padding;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    final safeChild = applySafeArea
        ? SafeArea(
            top: safeAreaTop,
            bottom: safeAreaBottom,
            child: child,
          )
        : child;
    final content = padding == null
        ? safeChild
        : Padding(
            padding: padding!,
            child: safeChild,
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.8),
          radius: 1.4,
          colors: [
            AppColors.surface,
            AppColors.base,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        child: content,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    const step = 56.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
