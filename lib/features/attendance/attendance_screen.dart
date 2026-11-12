import 'package:office_management/core/common.dart';

import 'work_status_panel.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Attendance',
      subtitle: 'Check in, breaks and monthly summary',
      builder: (context) {
        final app = context.watch<AppController>();
        final now = DateTime.now();
        final month = app.myAttendance.where((a) => a.date.year == now.year && a.date.month == now.month && !a.date.isAfter(dateOnly(now)));
        final s = AttendanceSummary.of(month);
        final today = app.myToday;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WorkStatusPanel(),
            const Gap(20),
            const SectionHeader(title: "Today's timeline"),
            AppCard(
              child: (today == null || today.events.isEmpty)
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: EmptyState(title: 'No activity yet', message: 'Your check-in, break and check-out events will appear here.', icon: Icons.timeline),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < today.events.length; i++) _eventRow(today.events[i], i == today.events.length - 1),
                      ],
                    ),
            ),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'This month', subtitle: Fmt.monthYear(now)),
            ResponsiveGrid(minTileWidth: 150, spacing: 12, children: [
              StatCard(label: 'Present', value: '${s.present + s.late}', icon: Icons.check_circle_outline, color: AppColors.success),
              StatCard(label: 'Late', value: '${s.late}', icon: Icons.watch_later_outlined, color: AppColors.warning),
              StatCard(label: 'WFH', value: '${s.wfh}', icon: Icons.home_work_outlined, color: AppColors.info),
              StatCard(label: 'Leave', value: '${s.leave}', icon: Icons.beach_access_outlined, color: AppColors.purple),
              StatCard(label: 'Avg hours', value: s.avgHours.toStringAsFixed(1), icon: Icons.timer_outlined, color: AppColors.teal),
              StatCard(label: 'Overtime', value: '${s.overtimeHours.toStringAsFixed(1)}h', icon: Icons.bolt, color: AppColors.orange),
            ]),
            const Gap(20),
            const SectionHeader(title: 'Quick access'),
            _link(context, Icons.history, 'Attendance history & calendar', '/employee/attendance/history'),
            const Gap(10),
            _link(context, Icons.edit_calendar_outlined, 'Regularization request', '/employee/attendance/regularization'),
            const Gap(10),
            _link(context, Icons.qr_code_scanner, 'QR attendance', '/employee/attendance/qr'),
          ],
        );
        return TwoColumn(left: left, right: right);
      },
    );
  }

  Widget _link(BuildContext context, IconData icon, String label, String path) => AppCard(
        onTap: () => context.push(path),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
      );

  Widget _eventRow(AttendanceEvent e, bool last) {
    final (icon, color) = switch (e.type) {
      AttendanceEventType.checkIn => (Icons.login_rounded, AppColors.success),
      AttendanceEventType.breakStart => (Icons.free_breakfast_outlined, AppColors.warning),
      AttendanceEventType.breakEnd => (Icons.play_arrow_rounded, AppColors.info),
      AttendanceEventType.checkOut => (Icons.logout_rounded, AppColors.danger),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha:0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
            if (!last) Expanded(child: Container(width: 2, color: AppColors.border)),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18, top: 6),
              child: Row(children: [
                Expanded(child: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(Fmt.time(e.time), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
