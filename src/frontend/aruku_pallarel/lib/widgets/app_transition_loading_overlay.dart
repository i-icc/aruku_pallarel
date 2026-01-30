import 'package:flutter/material.dart';

import '../theme/app_styles.dart';

class AppTransitionLoadingOverlay extends StatefulWidget {
  const AppTransitionLoadingOverlay({super.key});

  @override
  State<AppTransitionLoadingOverlay> createState() =>
      _AppTransitionLoadingOverlayState();
}

class _AppTransitionLoadingOverlayState
    extends State<AppTransitionLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AbsorbPointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.base,
                AppColors.surface,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFFFF32C2),
                              Color(0xFFFFA83F),
                              Color(0xFFFFF524),
                              Color(0xFFFF32C2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Center(
                        child: Text(
                          'ARUKU',
                          style: theme.textTheme.titleMedium?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '移動中...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
