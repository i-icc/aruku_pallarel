import 'package:flutter/material.dart';

class AppFloatingButton extends StatelessWidget {
  const AppFloatingButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 56.0,
    this.iconSize = 32.0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9), // Slightly less transparent for better visibility
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.grey,
          size: iconSize,
        ),
      ),
    );
  }
}
