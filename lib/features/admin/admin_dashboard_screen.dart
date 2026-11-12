import 'package:office_management/core/common.dart';
import 'package:office_management/shared/stats.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return PageScaffold(
      title: app.loaded ? '${Fmt.greeting()}, ${app.me.firstName}' : 'Dashboard',
      subtitle: 'Organisation overview - ${Fmt.fullDate(DateTime.now())}',
      showAccount: true,
      builder: (context) {
        final today = dateOnly(DateTime.now());
        final active = app.employees.where((e) => e.active).toList();
        final ids = active.map((e) => e.id).toSet();
        final c = statusCounts(app, ids, today);
        final pending = app.approvals().where((a) => a.status == RequestStatus.pending).toList();
        final days = lastWorkingDays(10);
        final deptNames = app.departments.map((d) => d.name).toList();

        final stats = ResponsiveGrid(minTileWidth: 170, spacing: 12, children: [
          StatCard(label: 'Active employees', value: '${active.length}', icon: Icons.badge_outlined, color: AppColors.navy, onTap: () => context.go('/admin/employees')),
          StatCard(label: 'Present today', value: '${(c[AttendanceStatus.present] ?? 0) + (c[AttendanceStatus.late] ?? 0)}', icon: Icons.check_circle_outline, color: AppColors.success),
          StatCard(label: 'On leave', value: '${c[AttendanceStatus.leave] ?? 0}', icon: Icons.beach_access_outlined, color: AppColors.purple),
          StatCard(label: 'Working from home', value: '${c[AttendanceStatus.wfh] ?? 0}', icon: Icons.home_work_outlined, color: AppColors.info),
          StatCard(label: 'Late today', value: '${c[AttendanceStatus.late] ?? 0}', icon: Icons.watch_later_outlined, color: AppColors.warning),
          StatCard(label: 'Pending approvals', value: '${pending.length}', icon: Icons.approval, color: AppColors.orange, onTap: () => context.go('/admin/leaves')),
        ]);

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Attendance trend', subtitle: 'Company-wide, last 10 working days'),
            AppCard(child: SimpleLineChart(values: [for (final d in days) attendancePct(app, ids, d)], labels: [for (final d in days) '${d.day}'], height: 180)),
            const Gap(20),
            const SectionHeader(title: 'Headcount by department'),
            AppCard(
              child: SimpleBarChart(
                values: [for (final d in deptNames) app.employeeCountIn(d).toDouble()],
                labels: deptNames,
                colors: const [AppColors.teal, AppColors.info, AppColors.purple, AppColors.orange, AppColors.navy],
              ),
            ),
            const Gap(20),
            SectionHeader(title: 'Recent activity', actionLabel: 'Audit logs', onAction: () => context.go('/admin/audit')),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: [
                for (var i = 0; i < 5 && i < app.auditLogs.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Icon(app.auditLogs[i].icon, color: AppColors.teal, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.auditLogs[i].action, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(app.auditLogs[i].target, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                        ]),
                      ),
                      Text(Fmt.relative(app.auditLogs[i].time), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ]),
                  ),
                  if (i != 4 && i != app.auditLogs.length - 1) const Divider(),
                ],
              ]),
            ),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: "Today's attendance"),
            AppCard(child: Center(child: DonutChart(segments: donutFor(c), centerValue: '${active.length}', centerLabel: 'employees'))),
            const Gap(20),
            const SectionHeader(title: 'Quick actions'),
            ResponsiveGrid(minTileWidth: 150, spacing: 10, children: [
              _Action(Icons.person_add_alt_outlined, 'Add employee', () => context.push('/admin/employees/add')),
              _Action(Icons.campaign_outlined, 'Announce', () => context.go('/admin/announcements')),
              _Action(Icons.bar_chart_rounded, 'Reports', () => context.go('/admin/reports')),
              _Action(Icons.celebration_outlined, 'Holidays', () => context.go('/admin/holidays')),
            ]),
            const Gap(20),
            SectionHeader(title: 'Awaiting approval', actionLabel: 'Review', onAction: () => context.go('/admin/leaves')),
            if (pending.isEmpty)
              const AppCard(child: EmptyState(title: 'No pending requests', icon: Icons.task_alt))
            else
              for (final p in pending.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ApprovalCard(
                    item: p,
                    employeeName: app.nameOf(p.employeeId),
                    onApprove: () async {
                      await app.reviewApproval(p, RequestStatus.approved);
                      if (context.mounted) showAppSnack(context, 'Request approved.');
                    },
                    onReject: () async {
                      await app.reviewApproval(p, RequestStatus.rejected);
                      if (context.mounted) showAppSnack(context, 'Request rejected.');
                    },
                  ),
                ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [stats, const Gap(22), TwoColumn(left: left, right: right, breakpoint: 950)],
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
