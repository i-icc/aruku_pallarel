import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class WalkSuggestPin extends StatelessWidget {
  const WalkSuggestPin({
    super.key,
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
