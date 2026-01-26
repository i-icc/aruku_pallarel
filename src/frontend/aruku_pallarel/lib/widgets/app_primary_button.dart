import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_styles.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.mPlusRounded1c(
                  textStyle: Theme.of(context).textTheme.titleMedium,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

    final child = Ink(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: content,
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: child,
      ),
    );

    if (!expand) {
      return Opacity(
        opacity: onPressed == null ? 0.6 : 1,
        child: button,
      );
    }

    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: SizedBox(
        width: double.infinity,
        child: button,
      ),
    );
  }
}
