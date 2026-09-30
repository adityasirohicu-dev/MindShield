import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class AiAttributionDriver extends StatelessWidget {
  final String factorName;
  final int impactPercentage;
  final String explanation;
  final bool isPositiveImpact;

  const AiAttributionDriver({
    super.key,
    required this.factorName,
    required this.impactPercentage,
    required this.explanation,
    required this.isPositiveImpact,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isPositiveImpact ? AppColors.nominal : AppColors.alert;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(factorName.toUpperCase(), style: AppTypography.labelMd),
              Text(
                '${isPositiveImpact ? '-' : '+'}$impactPercentage%',
                style: AppTypography.labelMd.copyWith(color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // The bar
          Container(
            height: 4,
            width: double.infinity,
            color: AppColors.surfaceContainerHigh,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: impactPercentage / 100,
              child: Container(
                color: barColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}
