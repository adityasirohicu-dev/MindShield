import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';

enum StatusChipVariant { nominal, advisory, alert, operational, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipVariant variant;

  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (variant) {
      case StatusChipVariant.nominal:
        backgroundColor = AppColors.nominalTint;
        textColor = AppColors.nominal;
        borderColor = AppColors.nominal;
        break;
      case StatusChipVariant.alert:
        backgroundColor = AppColors.alertTint;
        textColor = AppColors.alert;
        borderColor = AppColors.alert;
        break;
      case StatusChipVariant.advisory:
        backgroundColor = AppColors.advisoryTint;
        textColor = AppColors.advisory;
        borderColor = AppColors.advisory;
        break;
      case StatusChipVariant.operational:
        backgroundColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
        break;
      case StatusChipVariant.neutral:
        backgroundColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.textSecondary;
        borderColor = AppColors.borderEmphasis;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.pill,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSm.copyWith(color: textColor),
      ),
    );
  }
}
