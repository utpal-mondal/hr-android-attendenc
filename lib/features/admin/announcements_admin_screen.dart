import 'package:office_management/core/common.dart';
import 'package:office_management/features/announcements/announcements_screen.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  String _filter = 'All';

  void _editor(BuildContext context, {Announcement? existing}) {
    final formKey = GlobalKey<FormState>();
    final app = context.read<AppController>();
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    String category = existing?.category ?? 'News';
    String audience = existing?.audience ?? 'All employees';
    bool publish = existing?.published ?? true;
    final audiences = ['All employees', ...app.branches.map((b) => b.name), ...app.departments.map((d) => d.name)];
    if (!audiences.contains(audience)) audiences.add(audience);

    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(existing == null ? 'New announcement' : 'Edit announcement', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(label: 'Title', controller: title, validator: (v) => (v == null || v.trim().length < 5) ? 'Enter a title (min 5 characters)' : null),
              const SizedBox(height: 14),
              AppTextField(label: 'Message', controller: body, maxLines: 5, validator: (v) => (v == null || v.trim().length < 15) ? 'Write at least 15 characters' : null),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: AppDropdown<String>(label: 'Category', items: const ['Policy', 'Event', 'Holiday', 'HR', 'News'], value: category, onChanged: (v) => setS(() => category = v ?? 'News'))),
                const SizedBox(width: 12),
                Expanded(child: AppDropdown<String>(label: 'Audience', items: audiences, value: audience, onChanged: (v) => setS(() => audience = v ?? 'All employees'))),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish immediately', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Turn off to save as a draft'),
                value: publish,
                onChanged: (v) => setS(() => publish = v),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: publish ? 'Publish' : 'Save draft',
                icon: publish ? Icons.send_outlined : Icons.save_outlined,
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  app.saveAnnouncement(existing: existing, title: title.text.trim(), body: body.text.trim(), category: category, audience: audience, publish: publish);
                  Navigator.pop(ctx);
                  showAppSnack(context, publish ? 'Announcement published.' : 'Draft saved.');
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Announcements',
      subtitle: 'Create and manage company communication',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'New', icon: Icons.add, compact: true, onPressed: () => _editor(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.announcements.where((a) => _filter == 'All' || (_filter == 'Published' ? a.published : !a.published)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFilterChips<String>(options: const ['All', 'Published', 'Drafts'], selected: _filter, onSelected: (v) => setState(() => _filter = v)),
            const Gap(16),
            if (list.isEmpty)
              AppCard(child: EmptyState(title: 'No announcements', icon: Icons.campaign_outlined, actionLabel: 'Create one', onAction: () => _editor(context)))
            else
              ResponsiveGrid(minTileWidth: 480, spacing: 12, children: [
                for (final a in list)
                  AnnouncementCard(
                    announcement: a,
                    onTap: () => showAnnouncementSheet(context, a),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          _editor(context, existing: a);
                        } else if (v == 'publish') {
                          app.togglePublish(a);
                          showAppSnack(context, a.published ? 'Announcement published.' : 'Moved to drafts.');
                        } else if (v == 'delete') {
                          final ok = await showConfirmDialog(context, title: 'Delete announcement?', message: 'This cannot be undone.', confirmLabel: 'Delete', destructive: true);
                          if (ok) app.deleteAnnouncement(a);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'publish', child: Text(a.published ? 'Unpublish' : 'Publish')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
