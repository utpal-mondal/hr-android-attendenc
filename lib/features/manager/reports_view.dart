import 'package:office_management/core/common.dart';
import 'package:office_management/shared/stats.dart';

enum _Report { attendance, late, absent, overtime, leave, department }

/// Charts + rankings for a set of employees. Used by manager and HR reports.
class ReportsView extends StatefulWidget {
  const ReportsView({super.key, this.ids, this.includeDepartments = false});
  final Set<String>? ids;
  final bool includeDepartments;

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  _Report _report = _Report.attendance;
  int _period = 14;

  String _label(_Report r) => switch (r) {
        _Report.attendance => 'Attendance',
        _Report.late => 'Late arrivals',
        _Report.absent => 'Absenteeism',
        _Report.overtime => 'Overtime',
        _Report.leave => 'Leave usage',
        _Report.department => 'Departments',
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final employees = app.employees.where((e) => e.active && (widget.ids == null || widget.ids!.contains(e.id))).toList();
    final ids = employees.map((e) => e.id).toSet();
    final days = lastWorkingDays(_period);
    final records = app.attendanceBetween(days.first, days.last, ids: ids);
    final options = _Report.values.where((r) => r != _Report.department || widget.includeDepartments).toList();

    List<String> labels() => [for (var i = 0; i < days.length; i++) (days.length <= 8 || i % 2 == 0) ? '${days[i].day}' : ''];

    Widget content;
    switch (_report) {
      case _Report.attendance:
        {
        final vals = [for (final d in days) attendancePct(app, ids, d)];
        final avg = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
        final best = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a > b ? a : b);
        final worst = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a < b ? a : b);
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ResponsiveGrid(minTileWidth: 150, spacing: 10, children: [
            StatCard(label: 'Average attendance', value: '${avg.toStringAsFixed(1)}%', icon: Icons.insights, color: AppColors.teal),
            StatCard(label: 'Best day', value: '${best.toStringAsFixed(0)}%', icon: Icons.trending_up, color: AppColors.success),
            StatCard(label: 'Lowest day', value: '${worst.toStringAsFixed(0)}%', icon: Icons.trending_down, color: AppColors.danger),
          ]),
          const Gap(16),
          _chartCard('Daily attendance %', SimpleLineChart(values: vals, labels: labels(), height: 190)),
          const Gap(16),
          _ranking('Highest absence days', _countBy(records, (a) => a.status == AttendanceStatus.absent ? 1 : 0), app, suffix: ' day(s)'),
        ]);
        }
      case _Report.late:
        {
        final vals = [for (final d in days) records.where((a) => sameDay(a.date, d) && a.status == AttendanceStatus.late).length.toDouble()];
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _chartCard('Late arrivals per day', SimpleBarChart(values: vals, labels: labels(), color: AppColors.warning)),
          const Gap(16),
          _ranking('Most late arrivals', _countBy(records, (a) => a.status == AttendanceStatus.late ? 1 : 0), app, suffix: ' time(s)'),
        ]);
        }
      case _Report.absent:
        {
        final vals = [for (final d in days) records.where((a) => sameDay(a.date, d) && a.status == AttendanceStatus.absent).length.toDouble()];
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _chartCard('Absences per day', SimpleBarChart(values: vals, labels: labels(), color: AppColors.danger)),
          const Gap(16),
          _ranking('Most absences', _countBy(records, (a) => a.status == AttendanceStatus.absent ? 1 : 0), app, suffix: ' day(s)'),
        ]);
        }
      case _Report.overtime:
        {
        final vals = [
          for (final d in days) records.where((a) => sameDay(a.date, d) && a.checkOut != null).fold<double>(0, (s, a) => s + a.overtime.inMinutes / 60),
        ];
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _chartCard('Overtime hours per day', SimpleBarChart(values: vals, labels: labels(), color: AppColors.info, valueLabel: (v) => v.toStringAsFixed(0))),
          const Gap(16),
          _ranking('Highest overtime', _countBy(records, (a) => a.checkOut == null ? 0 : a.overtime.inMinutes / 60), app, suffix: ' h'),
        ]);
        }
      case _Report.leave:
        {
        final approved = app.leaves.where((l) => l.status == RequestStatus.approved && ids.contains(l.employeeId));
        final byType = <String, double>{};
        final byEmp = <String, double>{};
        for (final l in approved) {
          byType[l.type] = (byType[l.type] ?? 0) + l.days;
          byEmp[l.employeeId] = (byEmp[l.employeeId] ?? 0) + l.days;
        }
        final types = byType.keys.toList();
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (types.isEmpty)
            const AppCard(child: EmptyState(title: 'No approved leave', icon: Icons.beach_access_outlined))
          else
            _chartCard('Approved leave days by type', SimpleBarChart(values: [for (final t in types) byType[t]!], labels: [for (final t in types) t.split(' ').first], color: AppColors.purple)),
          const Gap(16),
          _ranking('Most leave taken', byEmp, app, suffix: ' day(s)'),
        ]);
        }
      case _Report.department:
        {
        final depts = app.departments.map((d) => d.name).toList();
        final vals = <double>[];
        for (final d in depts) {
          final dIds = employees.where((e) => e.department == d).map((e) => e.id).toSet();
          if (dIds.isEmpty) {
            vals.add(0);
            continue;
          }
          vals.add(days.fold<double>(0, (s, day) => s + attendancePct(app, dIds, day)) / days.length);
        }
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _chartCard('Average attendance % by department', SimpleBarChart(values: vals, labels: depts, color: AppColors.teal, maxValue: 100, valueLabel: (v) => '${v.toStringAsFixed(0)}%')),
          const Gap(16),
          ScrollableTable(
            columns: const ['Department', 'Headcount', 'Avg attendance'],
            rows: [
              for (var i = 0; i < depts.length; i++)
                [Text(depts[i], style: const TextStyle(fontWeight: FontWeight.w600)), Text('${employees.where((e) => e.department == depts[i]).length}'), Text('${vals[i].toStringAsFixed(1)}%')],
            ],
          ),
        ]);
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: AppFilterChips<_Report>(options: options, selected: _report, labelOf: _label, onSelected: (r) => setState(() => _report = r))),
        ]),
        const Gap(10),
        Row(children: [
          Expanded(
            child: AppFilterChips<int>(
              options: const [7, 14, 30],
              selected: _period,
              labelOf: (d) => 'Last $d working days',
              onSelected: (d) => setState(() => _period = d),
            ),
          ),
          AppButton(label: 'Export', icon: Icons.file_download_outlined, type: AppButtonType.secondary, compact: true, onPressed: () => showAppSnack(context, '${_label(_report)} report exported (demo).')),
        ]),
        const Gap(18),
        content,
      ],
    );
  }

  Widget _chartCard(String title, Widget chart) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          chart,
        ]),
      );

  Map<String, double> _countBy(List<Attendance> records, double Function(Attendance) f) {
    final m = <String, double>{};
    for (final a in records) {
      final v = f(a).toDouble();
      if (v > 0) m[a.employeeId] = (m[a.employeeId] ?? 0) + v;
    }
    return m;
  }

  Widget _ranking(String title, Map<String, double> data, AppController app, {String suffix = ''}) {
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        if (top.isEmpty)
          const AppCard(child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: [
              for (var i = 0; i < top.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 22, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
                    AvatarWidget(name: app.nameOf(top[i].key), size: 32),
                    const SizedBox(width: 10),
                    Expanded(child: Text(app.nameOf(top[i].key), style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${top[i].value % 1 == 0 ? top[i].value.toInt() : top[i].value.toStringAsFixed(1)}$suffix', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
                if (i != top.length - 1) const Divider(),
              ],
            ]),
          ),
      ],
    );
  }
}
