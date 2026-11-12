import 'package:office_management/core/common.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    ('How do I check in?', 'Open Home or Attendance and tap Check In. The app verifies your location against the office geofence (simulated in this demo) before marking you present.'),
    ('What if I forgot to check out?', 'Submit a regularization request from Attendance > Regularization. Your manager will review and approve it, after which your record is corrected.'),
    ('How is a late arrival calculated?', 'Checking in after your shift start time plus the grace period (usually 15 minutes) marks the day as Late.'),
    ('How many WFH days can I take?', 'Up to 6 days per calendar month, subject to manager approval.'),
    ('Where can I download my payslip?', 'Go to Payslips, open any month and tap Download PDF.'),
    ('Who approves my leave?', 'Your reporting manager approves leave. HR can view all requests and policies.'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Help & Support',
      shimmer: ShimmerLayout.list,
      maxWidth: 760,
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGrid(minTileWidth: 220, spacing: 12, children: [
              _contact(context, Icons.mail_outline, 'Email HR', 'hr@nexora.demo'),
              _contact(context, Icons.call_outlined, 'IT helpdesk', '+91 33 4000 1100'),
              _contact(context, Icons.support_agent, 'Open a ticket', 'Track in Helpdesk', onTap: () => context.go('/employee/helpdesk')),
            ]),
            const Gap(22),
            const SectionHeader(title: 'Frequently asked questions'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _faqs.length; i++) ...[
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        title: Text(_faqs[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                        children: [Text(_faqs[i].$2, style: const TextStyle(color: AppColors.textSecondary, height: 1.5))],
                      ),
                    ),
                    if (i != _faqs.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _contact(BuildContext context, IconData icon, String title, String sub, {VoidCallback? onTap}) => AppCard(
        onTap: onTap ?? () => showAppSnack(context, '$title: $sub (demo)'),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(sub, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      );
}
