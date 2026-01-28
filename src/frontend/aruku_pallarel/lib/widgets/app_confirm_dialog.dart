import 'package:flutter/material.dart';
import 'app_gradient_pill_button.dart';

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    this.description,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String? description;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const buttonHeight = 54.0;
    const halfButtonHeight = buttonHeight / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      // Stack would size itself to the non-positioned child (Card).
      // The button extends `halfButtonHeight` below the Stack's bottom logical boundary (because of the margin we add below).
      // Actually, if we add margin to the card, the Stack includes that margin in its size?
      // No, margin is outside the child. Stack sizes to child's constraints.
      // If child has margin, the Stack will be large enough to contain the child+margin.
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // File: Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: halfButtonHeight),
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 40 + halfButtonHeight), 
            // extra padding at bottom to prevent text from being covered by the button which sits half-way up
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 2,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (description != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) + 2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          // Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: buttonHeight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _CancelableFlatButton(
                      label: cancelLabel,
                      height: buttonHeight,
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppGradientPillButton(
                      label: confirmLabel,
                      height: buttonHeight,
                      isLoading: false,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelableFlatButton extends StatelessWidget {
  const _CancelableFlatButton({
    required this.label,
    required this.onTap,
    this.height = 68,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = height / 2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
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
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(radius - 6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
