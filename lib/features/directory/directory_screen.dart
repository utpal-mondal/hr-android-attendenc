import 'package:office_management/core/common.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _query = '';
  String _dept = 'All';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Employee Directory',
      subtitle: 'Find colleagues across all branches',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final q = _query.toLowerCase();
        final list = app.employees.where((e) {
          if (!e.active) return false;
          if (_dept != 'All' && e.department != _dept) return false;
          return q.isEmpty || e.name.toLowerCase().contains(q) || e.designation.toLowerCase().contains(q) || e.email.toLowerCase().contains(q);
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(hint: 'Search by name, role or email', onChanged: (v) => setState(() => _query = v)),
            const Gap(12),
            AppFilterChips<String>(options: ['All', ...app.departments.map((d) => d.name)], selected: _dept, onSelected: (v) => setState(() => _dept = v)),
            const Gap(14),
            Text('${list.length} colleague(s)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Gap(10),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No matches', message: 'Try a different name or department.', icon: Icons.person_search_outlined))
            else
              ResponsiveGrid(minTileWidth: 330, spacing: 12, children: [
                for (final e in list) EmployeeCard(employee: e, onTap: () => context.push('/employee/directory/${e.id}')),
              ]),
          ],
        );
      },
    );
  }
}
