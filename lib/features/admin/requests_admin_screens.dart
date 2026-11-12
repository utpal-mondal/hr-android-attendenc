import 'package:office_management/core/common.dart';
import 'package:office_management/features/manager/approvals_view.dart';

class AdminLeavesScreen extends StatelessWidget {
  const AdminLeavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Leave Management',
      subtitle: 'Company-wide leave requests and policy',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Annual leave policy'),
            ResponsiveGrid(minTileWidth: 170, spacing: 10, children: [
              for (final q in AppController.leaveQuota.entries)
                StatCard(label: q.key, value: '${q.value.toInt()} days', icon: Icons.beach_access_outlined, color: AppColors.purple),
            ]),
            const Gap(22),
            const SectionHeader(title: 'Requests'),
            const ApprovalsView(kinds: {ApprovalKind.leave}),
          ],
        );
      },
    );
  }
}

class AdminWfhScreen extends StatelessWidget {
  const AdminWfhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Work From Home',
      subtitle: 'Remote work requests across the company',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(children: [
                const Icon(Icons.policy_outlined, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(child: Text('Policy: up to ${AppController.wfhMonthlyQuota.toInt()} WFH days per month with manager approval.', style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
            const Gap(20),
            const ApprovalsView(kinds: {ApprovalKind.wfh}),
          ],
        );
      },
    );
  }
}
