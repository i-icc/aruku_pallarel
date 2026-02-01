import 'package:flutter/material.dart';

import '../../../../theme/app_styles.dart';

class WalkSuggestPopup extends StatelessWidget {
  const WalkSuggestPopup({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.tight,
            ),
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const _PopupPointer(),
      ],
    );
  }
}

class _PopupPointer extends StatelessWidget {
  const _PopupPointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 8),
      painter: _PopupPointerPainter(),
    );
  }
}

class _PopupPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
