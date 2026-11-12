import 'package:office_management/core/common.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  String _query = '';
  AttendanceStatus? _status;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'My Team',
      subtitle: 'Direct reports and today\'s status',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final today = dateOnly(DateTime.now());
        final q = _query.toLowerCase();
        final list = app.team.where((e) {
          if (q.isNotEmpty && !e.name.toLowerCase().contains(q) && !e.designation.toLowerCase().contains(q)) return false;
          if (_status != null && app.statusOn(e.id, today) != _status) return false;
          return true;
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(hint: 'Search team members', onChanged: (v) => setState(() => _query = v)),
            const Gap(12),
            AppFilterChips<AttendanceStatus?>(
              options: const [null, AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.wfh, AttendanceStatus.leave, AttendanceStatus.absent],
              selected: _status,
              labelOf: (s) => s == null ? 'All' : s.label,
              onSelected: (s) => setState(() => _status = s),
            ),
            const Gap(16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No team members found', icon: Icons.groups_outlined))
            else
              ResponsiveGrid(minTileWidth: 340, spacing: 12, children: [
                for (final e in list)
                  EmployeeCard(
                    employee: e,
                    badge: attendanceBadge(app.statusOn(e.id, today)),
                    onTap: () => context.push('/manager/team/${e.id}'),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
