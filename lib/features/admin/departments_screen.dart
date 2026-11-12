import 'package:office_management/core/common.dart';

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  void _members(BuildContext context, AppController app, Department d) {
    final list = app.employees.where((e) => e.department == d.name).toList();
    showAppSheet<void>(
      context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('${d.name} - ${list.length} members', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (final e in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EmployeeCard(
                      employee: e,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/admin/employees/${e.id}');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _add(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final desc = TextEditingController();
    String? head;
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('New department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Department name',
                controller: name,
                validator: (v) {
                  if (v == null || v.trim().length < 2) return 'Enter a name';
                  if (app.departments.any((d) => d.name.toLowerCase() == v.trim().toLowerCase())) return 'Department already exists';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppDropdown<String>(label: 'Department head', items: app.managers.map((m) => m.name).toList(), value: head, validator: (v) => v == null ? 'Select a head' : null, onChanged: (v) => setS(() => head = v)),
              const SizedBox(height: 14),
              AppTextField(label: 'Description', controller: desc, maxLines: 2),
              const SizedBox(height: 20),
              AppButton(
                label: 'Create department',
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  app.addDepartment(name.text.trim(), head!, desc.text.trim());
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Department created.');
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
      title: 'Departments',
      subtitle: 'Teams and leadership',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Add', icon: Icons.add, compact: true, onPressed: () => _add(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        return ResponsiveGrid(minTileWidth: 320, spacing: 14, children: [
          for (final d in app.departments)
            AppCard(
              onTap: () => _members(context, app, d),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_tree_outlined, color: AppColors.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  StatusBadge(label: '${app.employeeCountIn(d.name)} members', color: AppColors.info),
                ]),
                const SizedBox(height: 12),
                Text(d.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                IconText(Icons.person_outline, 'Head: ${d.head}'),
              ]),
            ),
        ]);
      },
    );
  }
}
