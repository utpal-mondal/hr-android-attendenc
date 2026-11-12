import 'package:office_management/core/common.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _query = '';
  String _dept = 'All';
  String _status = 'All';

  Future<void> _toggle(BuildContext context, AppController app, Employee e) async {
    final ok = await showConfirmDialog(
      context,
      title: e.active ? 'Deactivate ${e.name}?' : 'Activate ${e.name}?',
      message: e.active ? 'They will no longer appear in attendance, directory or approvals.' : 'They will be restored to active employees.',
      confirmLabel: e.active ? 'Deactivate' : 'Activate',
      destructive: e.active,
    );
    if (!ok) return;
    await app.toggleEmployeeActive(e);
    if (context.mounted) showAppSnack(context, e.active ? '${e.name} activated.' : '${e.name} deactivated.');
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Employees',
      subtitle: 'Manage your workforce',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Add', icon: Icons.person_add_alt_outlined, compact: true, onPressed: () => context.push('/admin/employees/add')),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final q = _query.toLowerCase();
        final list = app.employees.where((e) {
          if (_dept != 'All' && e.department != _dept) return false;
          if (_status == 'Active' && !e.active) return false;
          if (_status == 'Inactive' && e.active) return false;
          return q.isEmpty || e.name.toLowerCase().contains(q) || e.id.toLowerCase().contains(q) || e.email.toLowerCase().contains(q);
        }).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        final wide = Responsive.width(context) >= 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(hint: 'Search by name, ID or email', onChanged: (v) => setState(() => _query = v)),
            const Gap(12),
            AppFilterChips<String>(options: ['All', ...app.departments.map((d) => d.name)], selected: _dept, onSelected: (v) => setState(() => _dept = v)),
            const Gap(10),
            AppFilterChips<String>(options: const ['All', 'Active', 'Inactive'], selected: _status, onSelected: (v) => setState(() => _status = v)),
            const Gap(14),
            Text('${list.length} employee(s)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Gap(10),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No employees found', message: 'Adjust your filters or add a new employee.', icon: Icons.badge_outlined))
            else if (wide)
              ScrollableTable(
                columns: const ['Employee', 'ID', 'Department', 'Designation', 'Branch', 'Status', ''],
                rows: [
                  for (final e in list)
                    [
                      InkWell(
                        onTap: () => context.push('/admin/employees/${e.id}'),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AvatarWidget(name: e.name, size: 32),
                          const SizedBox(width: 10),
                          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(e.email, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                          ]),
                        ]),
                      ),
                      Text(e.id),
                      Text(e.department),
                      Text(e.designation),
                      Text(e.branch),
                      StatusBadge(label: e.active ? 'Active' : 'Inactive', color: e.active ? AppColors.success : AppColors.textSecondary),
                      PopupMenuButton<String>(
                        onSelected: (v) => v == 'view' ? context.push('/admin/employees/${e.id}') : _toggle(context, app, e),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'view', child: Text('View profile')),
                          PopupMenuItem(value: 'toggle', child: Text(e.active ? 'Deactivate' : 'Activate')),
                        ],
                      ),
                    ],
                ],
              )
            else
              Column(children: [
                for (final e in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Stack(children: [
                      EmployeeCard(employee: e, subtitleOverride: '${e.id}  -  ${e.designation}', onTap: () => context.push('/admin/employees/${e.id}')),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                          onSelected: (v) => v == 'view' ? context.push('/admin/employees/${e.id}') : _toggle(context, app, e),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'view', child: Text('View profile')),
                            PopupMenuItem(value: 'toggle', child: Text(e.active ? 'Deactivate' : 'Activate')),
                          ],
                        ),
                      ),
                    ]),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
