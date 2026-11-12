import 'package:office_management/core/common.dart';
import 'package:office_management/shared/stats.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return PageScaffold(
      title: app.loaded ? '${Fmt.greeting()}, ${app.me.firstName}' : 'Dashboard',
      subtitle: 'Team overview - ${Fmt.fullDate(DateTime.now())}',
      showAccount: true,
      builder: (context) {
        final today = dateOnly(DateTime.now());
        final team = app.team;
        final ids = app.teamIds;
        final c = statusCounts(app, ids, today);
        final pending = app.approvals(employeeIds: ids).where((a) => a.status == RequestStatus.pending).toList();
        final days = lastWorkingDays(7);

        final stats = ResponsiveGrid(minTileWidth: 150, spacing: 12, children: [
          StatCard(label: 'Team size', value: '${team.length}', icon: Icons.groups_outlined, color: AppColors.navy),
          StatCard(label: 'Present today', value: '${(c[AttendanceStatus.present] ?? 0) + (c[AttendanceStatus.late] ?? 0)}', icon: Icons.check_circle_outline, color: AppColors.success),
          StatCard(label: 'Late', value: '${c[AttendanceStatus.late] ?? 0}', icon: Icons.watch_later_outlined, color: AppColors.warning),
          StatCard(label: 'On leave', value: '${c[AttendanceStatus.leave] ?? 0}', icon: Icons.beach_access_outlined, color: AppColors.purple),
          StatCard(label: 'WFH', value: '${c[AttendanceStatus.wfh] ?? 0}', icon: Icons.home_work_outlined, color: AppColors.info),
          StatCard(label: 'Pending approvals', value: '${pending.length}', icon: Icons.approval, color: AppColors.orange, onTap: () => context.go('/manager/approvals')),
        ]);

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Team attendance trend', subtitle: 'Last 7 working days'),
            AppCard(
              child: SimpleLineChart(
                values: [for (final d in days) attendancePct(app, ids, d)],
                labels: [for (final d in days) dayLabel(d).split(' ').first],
                height: 170,
              ),
            ),
            const Gap(20),
            SectionHeader(title: 'Team status today', actionLabel: 'View team', onAction: () => context.go('/manager/team')),
            ResponsiveGrid(minTileWidth: 320, spacing: 10, children: [
              for (final e in team)
                EmployeeCard(
                  employee: e,
                  badge: attendanceBadge(app.statusOn(e.id, today)),
                  onTap: () => context.push('/manager/team/${e.id}'),
                ),
            ]),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Today at a glance'),
            AppCard(child: Center(child: DonutChart(segments: donutFor(c), centerValue: '${team.length}', centerLabel: 'team members'))),
            const Gap(20),
            SectionHeader(title: 'Needs your approval', actionLabel: 'Open', onAction: () => context.go('/manager/approvals')),
            if (pending.isEmpty)
              const AppCard(child: EmptyState(title: 'All caught up', message: 'No pending requests from your team.', icon: Icons.task_alt))
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
          children: [stats, const Gap(22), TwoColumn(left: left, right: right, leftFlex: 3, rightFlex: 2, breakpoint: 950)],
        );
      },
    );
  }
}
