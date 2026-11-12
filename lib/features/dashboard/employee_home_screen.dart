import 'package:office_management/core/common.dart';

import '../attendance/work_status_panel.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final title = app.loaded ? '${Fmt.greeting()}, ${app.me.firstName}' : 'Dashboard';
    return PageScaffold(
      title: title,
      subtitle: Fmt.fullDate(DateTime.now()),
      showAccount: true,
      actions: [
        if (Responsive.isMobile(context))
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/employee/notifications'),
            icon: Badge(isLabelVisible: app.unreadCount > 0, label: Text('${app.unreadCount}'), child: const Icon(Icons.notifications_none)),
          ),
      ],
      builder: (context) {
        final now = DateTime.now();
        final month = app.myAttendance.where((a) => a.date.year == now.year && a.date.month == now.month && !a.date.isAfter(dateOnly(now)));
        final s = AttendanceSummary.of(month);
        final balances = app.balancesFor(app.me.id);
        final leaveLeft = balances.fold<double>(0, (a, b) => a + b.remaining);
        final shift = app.shiftOf(app.me);
        final meetings = app.upcomingMeetings.take(3).toList();
        final news = app.publishedAnnouncements.take(3).toList();
        final pending = app.leavesFor(app.me.id).where((l) => l.status == RequestStatus.pending).length +
            app.wfhFor(app.me.id).where((l) => l.status == RequestStatus.pending).length +
            app.regularizationsFor(app.me.id).where((l) => l.status == RequestStatus.pending).length;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             WorkStatusPanel(),
            const Gap(20),
            SectionHeader(title: 'This month', subtitle: Fmt.monthYear(now)),
            ResponsiveGrid(minTileWidth: 150, spacing: 12, children: [
              StatCard(label: 'Days present', value: '${s.present + s.late}', icon: Icons.check_circle_outline, color: AppColors.success),
              StatCard(label: 'Late arrivals', value: '${s.late}', icon: Icons.watch_later_outlined, color: AppColors.warning),
              StatCard(label: 'WFH days', value: '${s.wfh}', icon: Icons.home_work_outlined, color: AppColors.info),
              StatCard(label: 'Leave balance', value: leaveLeft.toStringAsFixed(leaveLeft % 1 == 0 ? 0 : 1), icon: Icons.beach_access_outlined, color: AppColors.purple, onTap: () => context.go('/employee/leave')),
            ]),
            const Gap(20),
            const SectionHeader(title: 'Quick actions'),
            ResponsiveGrid(minTileWidth: 120, spacing: 10, children: [
              _Quick(Icons.event_available_outlined, 'Apply leave', AppColors.purple, () => context.push('/employee/leave/apply')),
              _Quick(Icons.home_work_outlined, 'Request WFH', AppColors.info, () => context.push('/employee/wfh/apply')),
              _Quick(Icons.edit_calendar_outlined, 'Regularize', AppColors.warning, () => context.push('/employee/attendance/regularization')),
              _Quick(Icons.qr_code_scanner, 'QR scan', AppColors.teal, () => context.push('/employee/attendance/qr')),
              _Quick(Icons.payments_outlined, 'Payslips', AppColors.success, () => context.go('/employee/payslips')),
              _Quick(Icons.support_agent, 'Helpdesk', AppColors.orange, () => context.go('/employee/helpdesk')),
            ]),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: "Today's schedule"),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.schedule, color: AppColors.teal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${shift.name} shift  -  ${Fmt.hm(shift.startHour, shift.startMinute)} to ${Fmt.hm(shift.endHour, shift.endMinute)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                  const Gap(8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.teal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(app.me.branch)),
                  ]),
                  const Divider(height: 28),
                  if (meetings.isEmpty)
                    const Text('No upcoming meetings.', style: TextStyle(color: AppColors.textSecondary))
                  else
                    for (final m in meetings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.info.withValues(alpha:0.10), borderRadius: BorderRadius.circular(8)),
                            child: Text(Fmt.time(m.start), style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text(sameDay(m.start, now) ? 'Today' : Fmt.dateShort(m.start), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                      ),
                  AppButton(label: 'All meetings', type: AppButtonType.text, compact: true, onPressed: () => context.go('/employee/meetings')),
                ],
              ),
            ),
            if (pending > 0) ...[
              const Gap(14),
              AppCard(
                color: AppColors.warning.withValues(alpha:0.06),
                borderColor: AppColors.warning.withValues(alpha:0.25),
                child: Row(children: [
                  const Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(child: Text('$pending request(s) awaiting manager approval', style: const TextStyle(fontWeight: FontWeight.w600))),
                ]),
              ),
            ],
            const Gap(20),
            SectionHeader(title: 'Announcements', actionLabel: 'View all', onAction: () => context.go('/employee/announcements')),
            for (final a in news)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: AnnouncementCard(announcement: a, compact: true, onTap: () => context.go('/employee/announcements'))),
          ],
        );
        return TwoColumn(left: left, right: right, breakpoint: 950);
      },
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}
