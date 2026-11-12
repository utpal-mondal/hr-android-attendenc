import 'package:office_management/core/common.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  RequestStatus? _filter;

  static const _colors = [AppColors.teal, AppColors.danger, AppColors.info, AppColors.purple];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Leave',
      subtitle: 'Balances, requests and history',
      actions: [
        AppButton(label: 'Apply', icon: Icons.add, compact: true, onPressed: () => context.push('/employee/leave/apply')),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final balances = app.balancesFor(app.me.id);
        final all = app.leavesFor(app.me.id);
        final list = all.where((l) => _filter == null || l.status == _filter).toList();
        int count(RequestStatus s) => all.where((l) => l.status == s).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Leave balance', subtitle: 'Remaining days this year'),
            ResponsiveGrid(minTileWidth: 230, children: [
              for (var i = 0; i < balances.length; i++) _balance(balances[i], _colors[i % _colors.length]),
            ]),
            const Gap(20),
            ResponsiveGrid(minTileWidth: 150, spacing: 12, children: [
              StatCard(label: 'Pending', value: '${count(RequestStatus.pending)}', icon: Icons.hourglass_top_rounded, color: AppColors.warning),
              StatCard(label: 'Approved', value: '${count(RequestStatus.approved)}', icon: Icons.check_circle_outline, color: AppColors.success),
              StatCard(label: 'Rejected', value: '${count(RequestStatus.rejected)}', icon: Icons.cancel_outlined, color: AppColors.danger),
            ]),
            const Gap(22),
            const SectionHeader(title: 'Leave history'),
            AppFilterChips<RequestStatus?>(
              options: const [null, RequestStatus.pending, RequestStatus.approved, RequestStatus.rejected],
              selected: _filter,
              labelOf: (s) => s == null ? 'All' : s.label,
              onSelected: (s) => setState(() => _filter = s),
            ),
            const Gap(14),
            if (list.isEmpty)
              AppCard(child: EmptyState(title: 'No leave requests', message: 'Requests you submit will appear here.', icon: Icons.beach_access_outlined, actionLabel: 'Apply for leave', onAction: () => context.push('/employee/leave/apply')))
            else
              ResponsiveGrid(minTileWidth: 420, children: [for (final l in list) LeaveCard(request: l)]),
          ],
        );
      },
    );
  }

  Widget _balance(LeaveBalance b, Color color) {
    String n(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.type, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(n(b.remaining), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color, height: 1)),
              Text('  / ${n(b.total)} days', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          LabeledProgress(value: (b.used + b.pending) / b.total, color: color),
          const SizedBox(height: 8),
          Text('${n(b.used)} used  -  ${n(b.pending)} pending', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
