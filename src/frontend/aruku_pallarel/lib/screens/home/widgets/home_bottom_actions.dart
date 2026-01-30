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
    const sideButtonSize = 56.0;
    const sideSpacing = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxCenterWidth = (availableWidth -
                (sideButtonSize * 2) -
                (sideSpacing * 2))
            .clamp(0.0, availableWidth)
            .toDouble();
        final preferredWidth = availableWidth * 0.55;
        final centerWidth =
            preferredWidth < maxCenterWidth ? preferredWidth : maxCenterWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // History Button
            AppFloatingButton(
              icon: Icons.history,
              onTap: onHistoryTap,
              size: sideButtonSize,
            ),
            const SizedBox(width: sideSpacing),
            // Start/Continue Button
            Transform.translate(
              offset: const Offset(0, 6),
              child: SizedBox(
                width: centerWidth,
                height: mainButtonHeight,
                child: AppGradientPillButton(
                  label: startWalkLabel,
                  isLoading: isStartWalkLoading,
                  height: mainButtonHeight,
                  fontSize: 22,
                  onPressed: onStartWalkTap,
                ),
              ),
            ),
            const SizedBox(width: sideSpacing),
            // Settings Button
            AppFloatingButton(
              icon: Icons.settings,
              onTap: onSettingsTap,
              size: sideButtonSize,
            ),
          ],
        );
      },
    );
  }
}
