import 'package:flutter/material.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<double> weeklyData;
  final List<String> labels;

  const WeeklyBarChart({
    Key? key,
    required this.weeklyData,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: CustomPaint(
        painter: WeeklyBarChartPainter(
          weeklyData: weeklyData,
          labels: labels,
        ),
      ),
    );
  }
}

class WeeklyBarChartPainter extends CustomPainter {
  final List<double> weeklyData;
  final List<String> labels;

  WeeklyBarChartPainter({
    required this.weeklyData,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty || labels.isEmpty) return;

    final maxData = weeklyData.reduce((a, b) => a > b ? a : b);
    final maxValue = maxData == 0 ? 100.0 : maxData * 1.2;

    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final paintBar = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final textStyle = const TextStyle(color: Colors.black54, fontSize: 12);
    
    final chartLeftPadding = 45.0;
    final chartBottomPadding = 30.0;
    final chartTopPadding = 20.0;
    final chartRightPadding = 10.0;

    final chartWidth = size.width - chartLeftPadding - chartRightPadding;
    final chartHeight = size.height - chartBottomPadding - chartTopPadding;

    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = chartTopPadding + chartHeight - (i * chartHeight / gridLines);
      canvas.drawLine(
        Offset(chartLeftPadding, y),
        Offset(size.width - chartRightPadding, y),
        paintGrid,
      );

      final value = (maxValue / gridLines) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatYLabel(value),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartLeftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    final barSpacing = chartWidth / weeklyData.length;
    final barWidth = barSpacing * 0.5;

    for (int i = 0; i < weeklyData.length; i++) {
      final x = chartLeftPadding + (i * barSpacing) + (barSpacing / 2);
      final barHeight = (weeklyData[i] / maxValue) * chartHeight;
      final y = chartTopPadding + chartHeight - barHeight;

      if (barHeight > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x - barWidth / 2, y, barWidth, barHeight),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(rect, paintBar);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartTopPadding + chartHeight + 8),
      );
    }
  }

  String _formatYLabel(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    if (oldDelegate.weeklyData.length != weeklyData.length) return true;
    for (int i = 0; i < weeklyData.length; i++) {
      if (oldDelegate.weeklyData[i] != weeklyData[i]) return true;
    }
    return false;
  }
}

