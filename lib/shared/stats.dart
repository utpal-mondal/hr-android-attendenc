

import '../controllers/app_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/charts.dart';
import '../models/enums.dart';

/// Status counts for [ids] on [day] (employees without a record count as absent).
Map<AttendanceStatus, int> statusCounts(AppController app, Iterable<String> ids, DateTime day) {
  final map = {for (final s in AttendanceStatus.values) s: 0};
  for (final id in ids) {
    final s = app.statusOn(id, day);
    map[s] = (map[s] ?? 0) + 1;
  }
  return map;
}

/// Last [n] working days (Mon-Fri) ending today, oldest first.
List<DateTime> lastWorkingDays(int n) {
  final out = <DateTime>[];
  var d = dateOnly(DateTime.now());
  while (out.length < n) {
    if (d.weekday < 6) out.add(d);
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return out.reversed.toList();
}

/// Percentage of [ids] who attended on [day].
double attendancePct(AppController app, Iterable<String> ids, DateTime day) {
  final list = ids.toList();
  if (list.isEmpty) return 0;
  final c = statusCounts(app, list, day);
  final attended = (c[AttendanceStatus.present] ?? 0) + (c[AttendanceStatus.late] ?? 0) + (c[AttendanceStatus.wfh] ?? 0) + (c[AttendanceStatus.halfDay] ?? 0);
  return attended / list.length * 100;
}

String dayLabel(DateTime d) => '${Fmt.weekday(d)} ${d.day}';

List<DonutSegment> donutFor(Map<AttendanceStatus, int> c) => [
      DonutSegment('Present', (c[AttendanceStatus.present] ?? 0).toDouble(), AppColors.success),
      DonutSegment('Late', (c[AttendanceStatus.late] ?? 0).toDouble(), AppColors.warning),
      DonutSegment('WFH', (c[AttendanceStatus.wfh] ?? 0).toDouble(), AppColors.info),
      DonutSegment('Leave', (c[AttendanceStatus.leave] ?? 0).toDouble(), AppColors.purple),
      DonutSegment('Absent', (c[AttendanceStatus.absent] ?? 0).toDouble(), AppColors.danger),
    ];
