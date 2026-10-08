import 'dart:math';
import 'package:flutter/material.dart';
import '../models/expense_category.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;

  const AnimatedDonutChart({Key? key, required this.data}) : super(key: key);

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold(0.0, (a, b) => a + b);
    
    if (total == 0) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('Chưa có dữ liệu chi tiêu', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: DonutChartPainter(
                  data: widget.data,
                  animationValue: _animation.value,
                  total: total,
                ),
                size: const Size(200, 200),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: e.key.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.key.name.toUpperCase()} (${(e.value / total * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double animationValue;
  final double total;

  DonutChartPainter({
    required this.data,
    required this.animationValue,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 20;
    
    // Draw background track
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;
    canvas.drawCircle(center, radius, bgPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;
    final totalAngle = 2 * pi * animationValue;

    for (var entry in data.entries) {
      if (entry.value <= 0) continue;
      
      final sweepAngle = (entry.value / total) * totalAngle;
      paint.color = entry.key.color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Tổng\n${total.toStringAsFixed(0)}đ',
        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.data != data || 
           oldDelegate.total != total;
  }
}

