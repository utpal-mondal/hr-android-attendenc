import 'package:office_management/core/common.dart';
import 'package:office_management/shared/stats.dart';

/// Daily attendance table/list for a set of employees (team or whole company).
class AttendanceBoard extends StatefulWidget {
  const AttendanceBoard({super.key, this.ids, this.showDepartmentFilter = false, this.profileBase = '/manager/team'});
  final Set<String>? ids; // null = everyone
  final bool showDepartmentFilter;
  final String profileBase;

  @override
  State<AttendanceBoard> createState() => _AttendanceBoardState();
}

class _Row {
  _Row(this.employee, this.record, this.status);
  final Employee employee;
  final Attendance? record;
  final AttendanceStatus status;
}

class _AttendanceBoardState extends State<AttendanceBoard> {
  DateTime _day = dateOnly(DateTime.now());
  AttendanceStatus? _status;
  String _dept = 'All';
  String _query = '';

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(now.year - 1), lastDate: dateOnly(now));
    if (d != null) setState(() => _day = d);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final scope = app.employees.where((e) => e.active && (widget.ids == null || widget.ids!.contains(e.id))).toList();
    final isWeekend = _day.weekday >= 6;
    final counts = statusCounts(app, scope.map((e) => e.id), _day);

    final q = _query.toLowerCase();
    final rows = <_Row>[];
    for (final e in scope) {
      if (_dept != 'All' && e.department != _dept) continue;
      if (q.isNotEmpty && !e.name.toLowerCase().contains(q)) continue;
      final rec = app.recordOn(e.id, _day);
      final st = rec?.status ?? AttendanceStatus.absent;
      if (_status != null && st != _status) continue;
      rows.add(_Row(e, rec, st));
    }
    rows.sort((a, b) => a.employee.name.compareTo(b.employee.name));
    final wide = Responsive.width(context) >= 760;
    final isToday = sameDay(_day, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _day = DateTime(_day.year, _day.month, _day.day - 1))),
            Expanded(
              child: InkWell(
                onTap: _pick,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: [
                    Text(Fmt.fullDate(_day), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(isToday ? 'Today - tap to change date' : 'Tap to change date', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: isToday ? null : () => setState(() => _day = DateTime(_day.year, _day.month, _day.day + 1))),
          ]),
        ),
        const Gap(14),
        if (!isWeekend) ResponsiveGrid(minTileWidth: 120, spacing: 10, children: [
          StatCard(label: 'Present', value: '${(counts[AttendanceStatus.present] ?? 0) + (counts[AttendanceStatus.late] ?? 0)}', icon: Icons.check_circle_outline, color: AppColors.success),
          StatCard(label: 'Late', value: '${counts[AttendanceStatus.late] ?? 0}', icon: Icons.watch_later_outlined, color: AppColors.warning),
          StatCard(label: 'WFH', value: '${counts[AttendanceStatus.wfh] ?? 0}', icon: Icons.home_work_outlined, color: AppColors.info),
          StatCard(label: 'Leave', value: '${counts[AttendanceStatus.leave] ?? 0}', icon: Icons.beach_access_outlined, color: AppColors.purple),
          StatCard(label: 'Absent', value: '${counts[AttendanceStatus.absent] ?? 0}', icon: Icons.cancel_outlined, color: AppColors.danger),
        ]),
        const Gap(16),
        if (!isWeekend) Row(children: [
          Expanded(child: SearchField(hint: 'Search employee', onChanged: (v) => setState(() => _query = v))),
          const SizedBox(width: 10),
          AppButton(label: 'Export', icon: Icons.file_download_outlined, type: AppButtonType.secondary, compact: true, onPressed: () => showAppSnack(context, 'Attendance report exported (demo).')),
        ]),
        const Gap(12),
        AppFilterChips<AttendanceStatus?>(
          options: const [null, AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.wfh, AttendanceStatus.leave, AttendanceStatus.absent],
          selected: _status,
          labelOf: (s) => s == null ? 'All' : s.label,
          onSelected: (s) => setState(() => _status = s),
        ),
        if (widget.showDepartmentFilter) ...[
          const Gap(10),
          AppFilterChips<String>(options: ['All', ...app.departments.map((d) => d.name)], selected: _dept, onSelected: (v) => setState(() => _dept = v)),
        ],
        const Gap(16),
        if (isWeekend)
          const AppCard(child: Text('Weekend - attendance is not tracked on this day.', style: TextStyle(color: AppColors.textSecondary))),
        if (!isWeekend && rows.isEmpty)
          const AppCard(child: EmptyState(title: 'No matching employees', message: 'Try changing the filters.', icon: Icons.search_off))
        else if (!isWeekend && wide)
          ScrollableTable(
            columns: const ['Employee', 'Department', 'Shift', 'Check-in', 'Check-out', 'Hours', 'Status'],
            rows: [
              for (final r in rows)
                [
                  InkWell(
                    onTap: () => context.push('${widget.profileBase}/${r.employee.id}'),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AvatarWidget(name: r.employee.name, size: 30),
                      const SizedBox(width: 10),
                      Text(r.employee.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Text(r.employee.department),
                  Text(r.employee.shift),
                  Text(Fmt.time(r.record?.checkIn)),
                  Text(r.record?.checkIn != null && r.record?.checkOut == null ? 'Working' : Fmt.time(r.record?.checkOut)),
                  Text(r.record?.checkIn == null ? '--' : Fmt.duration(r.record!.worked)),
                  attendanceBadge(r.status),
                ],
            ],
          )
        else if (!isWeekend)
          Column(children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EmployeeCard(
                  employee: r.employee,
                  subtitleOverride: r.record?.checkIn == null ? r.employee.designation : '${Fmt.time(r.record?.checkIn)} - ${r.record?.checkOut == null ? 'Working' : Fmt.time(r.record?.checkOut)}',
                  badge: attendanceBadge(r.status),
                  onTap: () => context.push('${widget.profileBase}/${r.employee.id}'),
                ),
              ),
          ]),
      ],
    );
  }
}
