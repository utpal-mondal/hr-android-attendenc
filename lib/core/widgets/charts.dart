import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = AppColors.teal,
    this.maxValue,
    this.height = 180,
    this.valueLabel,
    this.colors,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double? maxValue;
  final double height;
  final String Function(double)? valueLabel;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final max = maxValue ?? (values.isEmpty ? 1.0 : values.reduce(math.max));
    final safeMax = max <= 0 ? 1.0 : max;
    final barArea = height - 44;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(valueLabel != null ? valueLabel!(values[i]) : values[i].toStringAsFixed(values[i] % 1 == 0 ? 0 : 1),
                        maxLines: 1, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (values[i] / safeMax).clamp(0.0, 1.0).toDouble()),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => Container(
                        height: math.max(3.0, barArea * t),
                        decoration: BoxDecoration(
                          color: colors != null ? colors![i % colors!.length] : color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 14,
                      child: Text(labels[i], maxLines: 1, overflow: TextOverflow.clip, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
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

class DonutSegment {
  const DonutSegment(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.segments, required this.centerValue, required this.centerLabel, this.size = 160});
  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(segments),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerValue, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  Text(centerLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final s in segments)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${s.label} ${s.value.toInt()}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ]),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);
  final List<DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (total <= 0) {
      paint.color = AppColors.border;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (final s in segments) {
      if (s.value <= 0) continue;
      final sweep = s.value / total * math.pi * 2;
      paint.color = s.color;
      canvas.drawArc(rect, start, math.max(0.0, sweep - 0.03), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments;
}

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({super.key, required this.values, required this.labels, this.color = AppColors.teal, this.minY = 0, this.maxY = 100, this.height = 180, this.suffix = '%'});
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double minY;
  final double maxY;
  final double height;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _LinePainter(values, color, minY, maxY, suffix)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final l in labels)
              Expanded(child: Text(l, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary))),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color, this.minY, this.maxY, this.suffix);
  final List<double> values;
  final Color color;
  final double minY;
  final double maxY;
  final String suffix;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const leftPad = 34.0;
    final w = size.width - leftPad;
    for (var i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), grid);
      final v = minY + (maxY - minY) * i / 4;
      final tp = TextPainter(
        text: TextSpan(text: '${v.toStringAsFixed(0)}$suffix', style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, (y - tp.height / 2).clamp(0.0, size.height - tp.height).toDouble()));
    }
    if (values.length < 2) return;
    final n = values.length;
    Offset pt(int i) {
      final x = leftPad + w * (i + 0.5) / n;
      final double t = ((values[i] - minY) / (maxY - minY)).clamp(0.0, 1.0).toDouble();
      return Offset(x, size.height - size.height * t);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < n; i++) {
      final p0 = pt(i - 1);
      final p1 = pt(i);
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    final area = Path.from(path)
      ..lineTo(pt(n - 1).dx, size.height)
      ..lineTo(pt(0).dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha:0.22), color.withValues(alpha:0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = color;
    final ring = Paint()..color = Colors.white;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(pt(i), 4.5, ring);
      canvas.drawCircle(pt(i), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values;
}

/// Horizontal progress bar with label (used for leave balances etc.).
class LabeledProgress extends StatelessWidget {
  const LabeledProgress({super.key, required this.value, this.color = AppColors.teal, this.height = 8});
  final double value; // 0..1
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: height,
        backgroundColor: color.withValues(alpha:0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
