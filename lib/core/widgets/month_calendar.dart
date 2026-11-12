import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Monthly calendar grid with optional fills and marker dots.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.onMonthChanged,
    this.selected,
    this.onSelect,
    this.markersFor,
    this.fillFor,
    this.cellHeight = 52,
  });

  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelect;
  final List<Color> Function(DateTime)? markersFor;
  final Color? Function(DateTime)? fillFor;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final rows = ((lead + daysInMonth) / 7).ceil();
    final today = dateOnly(DateTime.now());
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1, 1)),
            ),
            Expanded(
              child: Text(Fmt.monthYear(month), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1, 1)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final l in labels)
              Expanded(child: Center(child: Text(l, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(r * 7 + c - lead + 1, daysInMonth, today)),
            ],
          ),
      ],
    );
  }

  Widget _cell(int dayNum, int daysInMonth, DateTime today) {
    if (dayNum < 1 || dayNum > daysInMonth) return SizedBox(height: cellHeight);
    final date = DateTime(month.year, month.month, dayNum);
    final isToday = sameDay(date, today);
    final isSel = selected != null && sameDay(date, selected!);
    final fill = fillFor?.call(date);
    final markers = markersFor?.call(date) ?? const <Color>[];
    return SizedBox(
      height: cellHeight,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onSelect == null ? null : () => onSelect!(date),
          child: Container(
            decoration: BoxDecoration(
              color: fill?.withValues(alpha:0.14),
              borderRadius: BorderRadius.circular(10),
              border: isSel
                  ? Border.all(color: AppColors.navy, width: 1.6)
                  : (isToday ? Border.all(color: AppColors.teal, width: 1.2) : null),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$dayNum',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isToday || isSel ? FontWeight.w800 : FontWeight.w500,
                      color: fill ?? AppColors.textPrimary,
                    )),
                if (markers.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final m in markers.take(3))
                        Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 5, height: 5, decoration: BoxDecoration(color: m, shape: BoxShape.circle)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
