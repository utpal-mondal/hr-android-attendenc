import 'package:office_management/core/common.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Employee Profile',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final e = app.employeeById(id);
        if (e == null) return const EmptyState(title: 'Employee not found', icon: Icons.person_off_outlined);
        final role = app.role;
        final canSeePrivate = role == UserRole.hr || role == UserRole.manager || e.id == app.me.id;
        return EmployeeProfileBody(employee: e, canSeePrivate: canSeePrivate);
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
          ],
        ),
      );
}

/// Profile header + tabbed details, shared by directory, team, admin and "My profile".
class EmployeeProfileBody extends StatefulWidget {
  const EmployeeProfileBody({super.key, required this.employee, this.canSeePrivate = true, this.footer});
  final Employee employee;
  final bool canSeePrivate;
  final Widget? footer;

  @override
  State<EmployeeProfileBody> createState() => _EmployeeProfileBodyState();
}

class _EmployeeProfileBodyState extends State<EmployeeProfileBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final e = widget.employee;
    final manager = e.managerId == null ? null : app.employeeById(e.managerId!);
    final tabs = ['Overview', if (widget.canSeePrivate) 'Attendance', if (widget.canSeePrivate) 'Leave'];
    if (_tab >= tabs.length) _tab = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 18,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AvatarWidget(name: e.name, size: 76),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(e.designation, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      StatusBadge(label: e.department, color: AppColors.info),
                      StatusBadge(label: e.role.label, color: AppColors.purple),
                      StatusBadge(label: e.active ? 'Active' : 'Inactive', color: e.active ? AppColors.success : AppColors.textSecondary),
                    ]),
                  ],
                ),
              ),
              Wrap(spacing: 10, runSpacing: 10, children: [
                AppButton(label: 'Email', icon: Icons.mail_outline, type: AppButtonType.secondary, compact: true, onPressed: () => showAppSnack(context, 'Opening email to ${e.email} (demo).')),
                AppButton(label: 'Call', icon: Icons.call_outlined, type: AppButtonType.secondary, compact: true, onPressed: () => showAppSnack(context, 'Calling ${e.phone} (demo).')),
              ]),
            ],
          ),
        ),
        const Gap(16),
        AppFilterChips<int>(options: List.generate(tabs.length, (i) => i), selected: _tab, labelOf: (i) => tabs[i], onSelected: (i) => setState(() => _tab = i)),
        const Gap(16),
        if (_tab == 0) _overview(e, manager?.name, app),
        if (_tab == 1 && widget.canSeePrivate) _attendance(app, e),
        if (_tab == 2 && widget.canSeePrivate) _leave(app, e),
        if (widget.footer != null) ...[const Gap(20), widget.footer!],
      ],
    );
  }

  Widget _overview(Employee e, String? managerName, AppController app) {
    final months = (DateTime.now().difference(e.joinDate).inDays / 30).floor();
    final personal = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Personal information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const Gap(8),
        _Info('Email', e.email),
        _Info('Phone', widget.canSeePrivate ? e.phone : 'Hidden'),
        _Info('Gender', e.gender),
        _Info('Address', widget.canSeePrivate ? e.address : 'Hidden'),
        _Info('Emergency', widget.canSeePrivate ? e.emergencyContact : 'Hidden'),
      ]),
    );
    final employment = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Employment details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const Gap(8),
        _Info('Employee ID', e.id),
        _Info('Department', e.department),
        _Info('Designation', e.designation),
        _Info('Branch', e.branch),
        _Info('Shift', e.shift),
        _Info('Reports to', managerName ?? '-'),
        _Info('Type', e.employmentType),
        _Info('Joined', '${Fmt.date(e.joinDate)} ($months months)'),
      ]),
    );
    return TwoColumn(left: personal, right: employment, leftFlex: 1, rightFlex: 1);
  }

  Widget _attendance(AppController app, Employee e) {
    final today = dateOnly(DateTime.now());
    final from = DateTime(today.year, today.month, today.day - 29);
    final records = app.attendanceBetween(from, today, ids: {e.id})..sort((a, b) => b.date.compareTo(a.date));
    final s = AttendanceSummary.of(records);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Last 30 days'),
        ResponsiveGrid(minTileWidth: 140, spacing: 10, children: [
          StatCard(label: 'Present', value: '${s.present}', icon: Icons.check_circle_outline, color: AppColors.success),
          StatCard(label: 'Late', value: '${s.late}', icon: Icons.watch_later_outlined, color: AppColors.warning),
          StatCard(label: 'Absent', value: '${s.absent}', icon: Icons.cancel_outlined, color: AppColors.danger),
          StatCard(label: 'Avg hours', value: s.avgHours.toStringAsFixed(1), icon: Icons.timer_outlined, color: AppColors.teal),
        ]),
        const Gap(16),
        const SectionHeader(title: 'Recent records'),
        ResponsiveGrid(minTileWidth: 400, children: [for (final r in records.take(8)) AttendanceCard(record: r)]),
      ],
    );
  }

  Widget _leave(AppController app, Employee e) {
    final balances = app.balancesFor(e.id);
    final leaves = app.leavesFor(e.id).take(4).toList();
    String n(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Leave balance'),
        ResponsiveGrid(minTileWidth: 170, spacing: 10, children: [
          for (final b in balances) StatCard(label: b.type, value: '${n(b.remaining)} / ${n(b.total)}', icon: Icons.beach_access_outlined, color: AppColors.purple),
        ]),
        const Gap(16),
        const SectionHeader(title: 'Recent leave requests'),
        if (leaves.isEmpty)
          const AppCard(child: Text('No leave requests.', style: TextStyle(color: AppColors.textSecondary)))
        else
          ResponsiveGrid(minTileWidth: 420, children: [for (final l in leaves) LeaveCard(request: l)]),
      ],
    );
  }
}
