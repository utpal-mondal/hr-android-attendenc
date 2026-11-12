import 'package:office_management/core/common.dart';

void showAnnouncementSheet(BuildContext context, Announcement a) {
  final color = categoryColor(a.category);
  showAppSheet<void>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              StatusBadge(label: a.category, color: color),
              const SizedBox(width: 8),
              if (a.pinned) const IconText(Icons.push_pin_outlined, 'Pinned'),
            ]),
            const SizedBox(height: 12),
            Text(a.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25)),
            const SizedBox(height: 8),
            Text('${a.author}  -  ${Fmt.fullDate(a.date)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            IconText(Icons.people_outline, a.audience),
            const Divider(height: 28),
            Text(a.body, style: const TextStyle(fontSize: 15, height: 1.55)),
            const SizedBox(height: 20),
            AppButton(label: 'Close', expand: true, type: AppButtonType.secondary, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Announcements',
      subtitle: 'News and updates from your company',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.publishedAnnouncements.where((a) {
          final q = _query.toLowerCase();
          final matchQ = q.isEmpty || a.title.toLowerCase().contains(q) || a.body.toLowerCase().contains(q);
          return matchQ && (_category == 'All' || a.category == _category);
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(hint: 'Search announcements', onChanged: (v) => setState(() => _query = v)),
            const Gap(12),
            AppFilterChips<String>(
              options: const ['All', 'Policy', 'Event', 'Holiday', 'HR', 'News'],
              selected: _category,
              onSelected: (v) => setState(() => _category = v),
            ),
            const Gap(16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No announcements found', message: 'Try a different search or category.', icon: Icons.campaign_outlined))
            else
              ResponsiveGrid(minTileWidth: 480, children: [for (final a in list) AnnouncementCard(announcement: a, onTap: () => showAnnouncementSheet(context, a))]),
          ],
        );
      },
    );
  }
}
