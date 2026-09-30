import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import 'status_chip.dart';

class GlassCard extends StatelessWidget {
  final String title;
  final StatusChipVariant? statusVariant;
  final Widget child;

  const GlassCard({
    super.key,
    required this.title,
    this.statusVariant,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: AppRadii.card,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B2A4A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderDefault),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.labelMd),
                if (statusVariant != null)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusVariant!),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          // Body
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Color _getStatusColor(StatusChipVariant variant) {
    switch (variant) {
      case StatusChipVariant.nominal:
        return AppColors.nominal;
      case StatusChipVariant.alert:
        return AppColors.alert;
      case StatusChipVariant.advisory:
        return AppColors.advisory;
      case StatusChipVariant.operational:
        return AppColors.primary;
      case StatusChipVariant.neutral:
        return AppColors.textDisabled;
    }
  }
}
