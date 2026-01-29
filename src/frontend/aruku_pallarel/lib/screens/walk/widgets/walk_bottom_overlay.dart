import 'package:flutter/material.dart';

import '../../../widgets/app_gradient_pill_button.dart';

class WalkBottomOverlay extends StatelessWidget {
  const WalkBottomOverlay({
    super.key,
    required this.notices,
    required this.mainButtonLabel,
    required this.isMainButtonLoading,
    required this.onMainButtonPressed,
  });

  final List<Widget> notices;
  final String mainButtonLabel;
  final bool isMainButtonLoading;
  final VoidCallback? onMainButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notices.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: notices,
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: 0.55,
            child: AppGradientPillButton(
              label: mainButtonLabel,
              isLoading: isMainButtonLoading,
              onPressed: onMainButtonPressed,
            ),
          ),
        ),
      ],
    );
  }
}
