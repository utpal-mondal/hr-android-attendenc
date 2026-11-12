import 'package:office_management/core/common.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  String _dayLabel(DateTime d) {
    final today = dateOnly(DateTime.now());
    if (sameDay(d, today)) return 'Today';
    if (sameDay(d, DateTime(today.year, today.month, today.day + 1))) return 'Tomorrow';
    return Fmt.fullDate(d);
  }

  void _detail(BuildContext context, Meeting m) {
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              IconText(Icons.event, Fmt.fullDate(m.start)),
              const SizedBox(height: 4),
              IconText(Icons.schedule, '${Fmt.time(m.start)} - ${Fmt.time(m.end)}'),
              const SizedBox(height: 4),
              IconText(Icons.location_on_outlined, m.location),
              const SizedBox(height: 16),
              const Text('Agenda', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final a in m.agenda)
                Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('\u2022  '), Expanded(child: Text(a))])),
              const SizedBox(height: 14),
              Text('Participants (${m.participantIds.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final id in m.participantIds)
                  Chip(avatar: AvatarWidget(name: app.nameOf(id), size: 22), label: Text(app.nameOf(id).split(' ').first), visualDensity: VisualDensity.compact),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: AppButton(
                    label: 'Copy link',
                    icon: Icons.link,
                    type: AppButtonType.secondary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: m.link));
                      Navigator.pop(ctx);
                      showAppSnack(context, 'Meeting link copied.');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Join',
                    icon: Icons.videocam_outlined,
                    onPressed: () {
                      Navigator.pop(ctx);
                      showAppSnack(context, 'Joining meeting (demo)...');
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Meetings',
      subtitle: 'Your upcoming schedule',
      shimmer: ShimmerLayout.list,
      maxWidth: 820,
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.upcomingMeetings;
        if (list.isEmpty) return const EmptyState(title: 'No upcoming meetings', icon: Icons.videocam_off_outlined);
        final groups = <DateTime, List<Meeting>>{};
        for (final m in list) {
          groups.putIfAbsent(dateOnly(m.start), () => []).add(m);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in groups.entries) ...[
              SectionHeader(title: _dayLabel(entry.key)),
              for (final m in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => _detail(context, m),
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 74,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.info.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Text(Fmt.time(m.start).split(' ').first, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(Fmt.time(m.start).split(' ').last, style: const TextStyle(color: AppColors.info, fontSize: 11.5)),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Wrap(spacing: 12, children: [
                            IconText(Icons.timer_outlined, '${m.end.difference(m.start).inMinutes} min'),
                            IconText(Icons.people_outline, '${m.participantIds.length}'),
                            IconText(Icons.location_on_outlined, m.location),
                          ]),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ]),
                  ),
                ),
              const Gap(8),
            ],
          ],
        );
      },
    );
  }
}
