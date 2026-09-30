import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';

enum PrimaryButtonVariant { primary, command, secondary, destructive }

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonVariant variant;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PrimaryButtonVariant.primary,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case PrimaryButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case PrimaryButtonVariant.command:
        backgroundColor = AppColors.command;
        textColor = Colors.white;
        break;
      case PrimaryButtonVariant.secondary:
        backgroundColor = Colors.white;
        textColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.borderEmphasis);
        break;
      case PrimaryButtonVariant.destructive:
        backgroundColor = AppColors.alert;
        textColor = Colors.white;
        break;
    }

    final button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.control,
        side: borderSide,
      ),
      child: InkWell(
        borderRadius: AppRadii.control,
        onTap: onPressed == null ? null : () {
          HapticFeedback.selectionClick();
          onPressed!.call();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelLg.copyWith(color: textColor),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
