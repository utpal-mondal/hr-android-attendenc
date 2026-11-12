import 'package:office_management/core/common.dart';

Color _statusColor(String s) => switch (s) {
      'Resolved' => AppColors.success,
      'In Progress' => AppColors.info,
      _ => AppColors.warning,
    };

Color _priorityColor(String s) => switch (s) {
      'High' => AppColors.danger,
      'Medium' => AppColors.warning,
      _ => AppColors.textSecondary,
    };

class HelpdeskScreen extends StatelessWidget {
  const HelpdeskScreen({super.key});

  void _newTicket(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final subject = TextEditingController();
    final message = TextEditingController();
    String? category;
    String priority = 'Medium';

    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                AppTextField(label: 'Subject', controller: subject, validator: (v) => (v == null || v.trim().length < 5) ? 'Enter a subject (min 5 characters)' : null),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Category',
                      items: context.read<AppController>().ticketCategories,
                      value: category,
                      validator: (v) => v == null ? 'Select category' : null,
                      onChanged: (v) => setS(() => category = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdown<String>(label: 'Priority', items: const ['Low', 'Medium', 'High'], value: priority, onChanged: (v) => setS(() => priority = v ?? 'Medium')),
                  ),
                ]),
                const SizedBox(height: 14),
                AppTextField(label: 'Describe the issue', controller: message, maxLines: 4, validator: (v) => (v == null || v.trim().length < 10) ? 'Please add more detail' : null),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Submit ticket',
                  expand: true,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    context.read<AppController>().createTicket(subject: subject.text.trim(), category: category!, priority: priority, message: message.text.trim());
                    Navigator.pop(ctx);
                    showAppSnack(context, 'Ticket created. Our team will respond soon.');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _conversation(BuildContext context, Ticket t) {
    final reply = TextEditingController();
    showAppSheet<void>(
      context,
      builder: (ctx) => Consumer<AppController>(
        builder: (ctx, app, _) => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${t.id}  -  ${t.subject}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, children: [
                    StatusBadge(label: t.status, color: _statusColor(t.status)),
                    StatusBadge(label: '${t.priority} priority', color: _priorityColor(t.priority)),
                    StatusBadge(label: t.category, color: AppColors.navy),
                  ]),
                ]),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final m in t.messages)
                      Align(
                        alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: m.fromMe ? AppColors.navy : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.sender, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: m.fromMe ? Colors.white70 : AppColors.teal)),
                              const SizedBox(height: 3),
                              Text(m.text, style: TextStyle(color: m.fromMe ? Colors.white : AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(Fmt.relative(m.time), style: TextStyle(fontSize: 10.5, color: m.fromMe ? Colors.white54 : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (t.status != 'Resolved')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(children: [
                    Expanded(child: TextField(controller: reply, decoration: const InputDecoration(hintText: 'Write a reply...'))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.navy),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      onPressed: () {
                        final text = reply.text.trim();
                        if (text.isEmpty) return;
                        app.replyTicket(t, text);
                        reply.clear();
                      },
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Helpdesk',
      subtitle: 'IT, HR and facilities support',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'New ticket', icon: Icons.add, compact: true, onPressed: () => _newTicket(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.ticketsFor(app.me.id);
        int count(String s) => list.where((t) => t.status == s).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGrid(minTileWidth: 150, spacing: 12, children: [
              StatCard(label: 'Open', value: '${count('Open')}', icon: Icons.mark_email_unread_outlined, color: AppColors.warning),
              StatCard(label: 'In progress', value: '${count('In Progress')}', icon: Icons.autorenew, color: AppColors.info),
              StatCard(label: 'Resolved', value: '${count('Resolved')}', icon: Icons.task_alt, color: AppColors.success),
            ]),
            const Gap(20),
            const SectionHeader(title: 'My tickets'),
            if (list.isEmpty)
              AppCard(child: EmptyState(title: 'No tickets', message: 'Raise a ticket and we will help you out.', icon: Icons.support_agent, actionLabel: 'New ticket', onAction: () => _newTicket(context)))
            else
              ResponsiveGrid(minTileWidth: 440, spacing: 12, children: [
                for (final t in list)
                  AppCard(
                    onTap: () => _conversation(context, t),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(t.id, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 12.5)),
                          const Spacer(),
                          StatusBadge(label: t.status, color: _statusColor(t.status)),
                        ]),
                        const SizedBox(height: 6),
                        Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 14, children: [
                          IconText(Icons.category_outlined, t.category),
                          IconText(Icons.flag_outlined, t.priority, color: _priorityColor(t.priority)),
                          IconText(Icons.chat_bubble_outline, '${t.messages.length}'),
                          IconText(Icons.schedule, Fmt.relative(t.created)),
                        ]),
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
