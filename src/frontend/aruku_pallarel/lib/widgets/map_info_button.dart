import 'package:flutter/material.dart';

import '../theme/app_styles.dart';

class MapInfoButton extends StatelessWidget {
  const MapInfoButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.tight,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
