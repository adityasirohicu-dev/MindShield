import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'status_chip.dart';

class RadialGauge extends StatelessWidget {
  final double score; // 0 to 100
  final String title;
  final StatusChipVariant statusVariant;

  const RadialGauge({
    super.key,
    required this.score,
    required this.title,
    required this.statusVariant,
  });

  @override
  Widget build(BuildContext context) {
    Color activeColor;
    switch (statusVariant) {
      case StatusChipVariant.nominal:
        activeColor = AppColors.nominal;
        break;
      case StatusChipVariant.alert:
        activeColor = AppColors.alert;
        break;
      case StatusChipVariant.advisory:
        activeColor = AppColors.advisory;
        break;
      case StatusChipVariant.operational:
        activeColor = AppColors.primary;
        break;
      case StatusChipVariant.neutral:
        activeColor = AppColors.textDisabled;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _GaugePainter(
                  score: score,
                  activeColor: activeColor,
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toInt().toString(),
                      style: AppTypography.headlineLg.copyWith(fontSize: 48),
                    ),
                    Text(
                      'INDEX',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatusChip(label: title, variant: statusVariant),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color activeColor;
  final Color backgroundColor;

  _GaugePainter({
    required this.score,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square; // Brutalist flat cap

    // Draw background track
    canvas.drawCircle(center, radius, bgPaint);

    // Draw active track (score / 100)
    final sweepAngle = 2 * pi * (score / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
