import 'package:office_management/core/common.dart';

enum _HistoryView { list, calendar }

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  _HistoryView _view = _HistoryView.list;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selected = dateOnly(DateTime.now());
  AttendanceStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Attendance History',
      subtitle: 'Daily records, hours and overtime',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final all = app.myAttendance;
        final monthRecords = all.where((a) => a.date.year == _month.year && a.date.month == _month.month).toList();
        final summary = AttendanceSummary.of(monthRecords.where((a) => !a.date.isAfter(dateOnly(DateTime.now()))));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<_HistoryView>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: _HistoryView.list, label: Text('List'), icon: Icon(Icons.view_list_outlined, size: 18)),
                      ButtonSegment(value: _HistoryView.calendar, label: Text('Calendar'), icon: Icon(Icons.calendar_month_outlined, size: 18)),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
              ],
            ),
            const Gap(16),
            ResponsiveGrid(minTileWidth: 140, spacing: 10, children: [
              StatCard(label: 'Present', value: '${summary.present}', icon: Icons.check_circle_outline, color: AppColors.success),
              StatCard(label: 'Late', value: '${summary.late}', icon: Icons.watch_later_outlined, color: AppColors.warning),
              StatCard(label: 'Leave / WFH', value: '${summary.leave} / ${summary.wfh}', icon: Icons.event_busy_outlined, color: AppColors.purple),
              StatCard(label: 'Absent', value: '${summary.absent}', icon: Icons.cancel_outlined, color: AppColors.danger),
            ]),
            const Gap(18),
            if (_view == _HistoryView.list) _list(context, monthRecords) else _calendar(context, app, monthRecords),
          ],
        );
      },
    );
  }

  Widget _monthBar() => Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1))),
          Expanded(child: Text(Fmt.monthYear(_month), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1))),
        ],
      );

  Widget _list(BuildContext context, List<Attendance> monthRecords) {
    final filtered = monthRecords.where((a) => _filter == null || a.status == _filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _monthBar(),
        AppFilterChips<AttendanceStatus?>(
          options: const [null, AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.wfh, AttendanceStatus.leave, AttendanceStatus.absent],
          selected: _filter,
          labelOf: (s) => s == null ? 'All' : s.label,
          onSelected: (s) => setState(() => _filter = s),
        ),
        const Gap(14),
        if (filtered.isEmpty)
          const AppCard(child: EmptyState(title: 'No records', message: 'No attendance records match this filter for the selected month.', icon: Icons.event_busy_outlined))
        else
          ResponsiveGrid(
            minTileWidth: 400,
            children: [
              for (final a in filtered)
                AttendanceCard(record: a, onTap: () => context.push('/employee/attendance/details?id=${a.id}')),
            ],
          ),
      ],
    );
  }

  Widget _calendar(BuildContext context, AppController app, List<Attendance> monthRecords) {
    Attendance? recFor(DateTime d) {
      for (final a in monthRecords) {
        if (sameDay(a.date, d)) return a;
      }
      return null;
    }

    final sel = _selected;
    final selRec = sel == null ? null : recFor(sel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: MonthCalendar(
            month: _month,
            selected: _selected,
            onMonthChanged: (m) => setState(() => _month = m),
            onSelect: (d) => setState(() => _selected = d),
            fillFor: (d) {
              final r = recFor(d);
              return r?.status.color;
            },
          ),
        ),
        const Gap(12),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final s in [AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.absent, AttendanceStatus.leave, AttendanceStatus.wfh, AttendanceStatus.holiday])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text(s.label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ]),
        ]),
        const Gap(16),
        SectionHeader(title: sel == null ? 'Select a day' : Fmt.fullDate(sel)),
        if (selRec != null)
          AttendanceCard(record: selRec, onTap: () => context.push('/employee/attendance/details?id=${selRec.id}'))
        else
          AppCard(
            child: Text(
              sel != null && sel.weekday >= 6 ? 'Weekend - no attendance expected.' : 'No attendance record for this day.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
