import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/colors.dart';
import '../theme/typography.dart';

class TrendChart extends StatelessWidget {
  final List<double> stressData;
  final List<double> recoveryData;
  final List<String> labels;
  final String? spikeLabel;
  final int? spikeIndex;

  const TrendChart({
    super.key,
    required this.stressData,
    required this.recoveryData,
    required this.labels,
    this.spikeLabel,
    this.spikeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _buildLegendItem('STRESS LOAD', AppColors.alert),
            const SizedBox(width: 16),
            _buildLegendItem('RECOVERY', AppColors.nominal),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _TrendChartPainter(
              stressData: stressData,
              recoveryData: recoveryData,
              stressColor: AppColors.alert,
              recoveryColor: AppColors.nominal,
              gridColor: AppColors.borderDefault,
              spikeIndex: spikeIndex,
            ),
            child: Container(),
          ),
        ),
        const SizedBox(height: 8),
        // X-axis labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (l) => Text(l, style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)),
              )
              .toList(),
        ),
        if (spikeLabel != null && spikeIndex != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.alertTint,
              border: Border.all(color: AppColors.alert),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward, size: 12, color: AppColors.alert),
                const SizedBox(width: 4),
                Text(spikeLabel!, style: AppTypography.labelSm.copyWith(color: AppColors.alert)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: color),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> stressData;
  final List<double> recoveryData;
  final Color stressColor;
  final Color recoveryColor;
  final Color gridColor;
  final int? spikeIndex;

  _TrendChartPainter({
    required this.stressData,
    required this.recoveryData,
    required this.stressColor,
    required this.recoveryColor,
    required this.gridColor,
    this.spikeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw 4 horizontal grid lines
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawLine(canvas, size, stressData, stressColor);
    _drawLine(canvas, size, recoveryData, recoveryColor);

    // Draw spike marker
    if (spikeIndex != null && spikeIndex! < stressData.length) {
      final allData = [...stressData, ...recoveryData];
      final maxVal = allData.reduce(max);
      final minVal = allData.reduce(min);
      final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
      final step = size.width / (stressData.length - 1);
      final x = spikeIndex! * step;
      final y = size.height - ((stressData[spikeIndex!] - minVal) / range) * size.height;

      final spikePaint = Paint()
        ..color = stressColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), spikePaint);

      final dotPaint = Paint()
        ..color = stressColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 8, height: 8),
        dotPaint,
      );
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;
    final allData = [...stressData, ...recoveryData];
    final maxVal = allData.reduce(max);
    final minVal = allData.reduce(min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final step = size.width / (data.length - 1);
      final x = i * step;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final step = size.width / (data.length - 1);
      final x = i * step;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
