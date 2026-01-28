import 'package:flutter/material.dart';

class AppGradientPillButton extends StatelessWidget {
  const AppGradientPillButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.height = 68,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double height;

  static const List<Color> _baseColors = [
    Color(0xFFDFFF33),
    Color(0xFF3FFF8B),
    Color(0xFF22FFD9),
  ];

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final radius = height / 2;

    final outerColors = _baseColors
        .map(
          (color) => Color.lerp(color, Colors.white, 0.72)!,
        )
        .toList();

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: outerColors,
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(radius - 6)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _baseColors,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}


