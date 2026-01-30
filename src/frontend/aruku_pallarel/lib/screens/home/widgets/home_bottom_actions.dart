import 'package:flutter/material.dart';
import '../../../widgets/app_floating_button.dart';
import '../../../widgets/app_gradient_pill_button.dart';

class HomeBottomActions extends StatelessWidget {
  const HomeBottomActions({
    super.key,
    required this.onHistoryTap,
    required this.onSettingsTap,
    required this.onStartWalkTap,
    required this.startWalkLabel,
    required this.isStartWalkLoading,
  });

  final VoidCallback onHistoryTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartWalkTap;
  final String startWalkLabel;
  final bool isStartWalkLoading;

  @override
  Widget build(BuildContext context) {
    const mainButtonHeight = 68.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // History Button
        AppFloatingButton(
          icon: Icons.history,
          onTap: onHistoryTap,
        ),
        const SizedBox(width: 16),
        // Start/Continue Button
        Expanded(
          child: SizedBox(
            height: mainButtonHeight,
            child: AppGradientPillButton(
              label: startWalkLabel,
              isLoading: isStartWalkLoading,
              height: mainButtonHeight,
              onPressed: onStartWalkTap,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Settings Button
        AppFloatingButton(
          icon: Icons.settings,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}
