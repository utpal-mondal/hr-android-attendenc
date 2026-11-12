import 'package:office_management/core/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String t) => switch (t) {
        'attendance' => Icons.fingerprint,
        'leave' => Icons.beach_access_outlined,
        'announcement' => Icons.campaign_outlined,
        'meeting' => Icons.videocam_outlined,
        _ => Icons.info_outline,
      };

  Color _color(String t) => switch (t) {
        'attendance' => AppColors.success,
        'leave' => AppColors.purple,
        'announcement' => AppColors.orange,
        'meeting' => AppColors.info,
        _ => AppColors.teal,
      };

  String _group(DateTime t) {
    final today = dateOnly(DateTime.now());
    final d = dateOnly(t);
    if (sameDay(d, today)) return 'Today';
    if (sameDay(d, DateTime(today.year, today.month, today.day - 1))) return 'Yesterday';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Notifications',
      shimmer: ShimmerLayout.list,
      maxWidth: 760,
      actions: [
        Consumer<AppController>(
          builder: (context, app, _) => AppButton(
            label: 'Mark all read',
            icon: Icons.done_all,
            type: AppButtonType.text,
            compact: true,
            onPressed: app.unreadCount == 0 ? null : app.markAllRead,
          ),
        ),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        if (app.notifications.isEmpty) {
          return const EmptyState(title: 'No notifications', message: "You're all caught up.", icon: Icons.notifications_none);
        }
        final groups = <String, List<AppNotification>>{};
        for (final n in app.notifications) {
          groups.putIfAbsent(_group(n.time), () => []).add(n);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in ['Today', 'Yesterday', 'Earlier'])
              if (groups[g] != null) ...[
                SectionHeader(title: g),
                for (final n in groups[g]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => app.markRead(n),
                      color: n.read ? Colors.white : AppColors.teal.withValues(alpha:0.05),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: _color(n.type).withValues(alpha:0.12), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_icon(n.type), color: _color(n.type), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(Fmt.relative(n.time), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (!n.read) Container(margin: const EdgeInsets.only(top: 6), width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }
}
