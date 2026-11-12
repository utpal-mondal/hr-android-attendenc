import 'package:office_management/core/common.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Audit Logs',
      subtitle: 'Track administrative actions',
      shimmer: ShimmerLayout.list,
      maxWidth: 860,
      builder: (context) {
        final app = context.watch<AppController>();
        final q = _query.toLowerCase();
        final list = app.auditLogs.where((l) => q.isEmpty || l.action.toLowerCase().contains(q) || l.target.toLowerCase().contains(q) || l.actor.toLowerCase().contains(q)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(hint: 'Search actions, targets or users', onChanged: (v) => setState(() => _query = v)),
            const Gap(16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No log entries', icon: Icons.history))
            else
              for (final l in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                        child: Icon(l.icon, color: AppColors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.action, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(l.target, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('by ${l.actor}  -  ${Fmt.date(l.time)}, ${Fmt.time(l.time)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ]),
                      ),
                      Text(Fmt.relative(l.time), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
          ],
        );
      },
    );
  }
}
