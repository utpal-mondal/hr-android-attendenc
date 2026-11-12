import 'package:office_management/core/common.dart';
import 'package:office_management/features/assets/assets_screen.dart';

class AdminAssetsScreen extends StatefulWidget {
  const AdminAssetsScreen({super.key});

  @override
  State<AdminAssetsScreen> createState() => _AdminAssetsScreenState();
}

class _AdminAssetsScreenState extends State<AdminAssetsScreen> {
  String _status = 'All';
  String _query = '';

  void _add(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final serial = TextEditingController();
    String type = 'Laptop';
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add asset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(label: 'Asset name', controller: name, validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a name' : null),
              const SizedBox(height: 14),
              AppDropdown<String>(label: 'Type', items: const ['Laptop', 'Monitor', 'Access Card', 'Phone', 'Accessory'], value: type, onChanged: (v) => setS(() => type = v ?? 'Laptop')),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Serial number',
                controller: serial,
                validator: (v) {
                  if (v == null || v.trim().length < 4) return 'Enter a serial number';
                  if (app.assets.any((a) => a.serial.toLowerCase() == v.trim().toLowerCase())) return 'Serial already registered';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add asset',
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  app.addAsset(name: name.text.trim(), type: type, serial: serial.text.trim());
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Asset added to inventory.');
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _assign(BuildContext context, Asset a) {
    final app = context.read<AppController>();
    String? emp;
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assign ${a.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Employee',
              hint: 'Select employee',
              items: app.employees.where((e) => e.active).map((e) => e.id).toList(),
              itemLabel: (id) => '${app.nameOf(id)} - ${app.employeeById(id)?.department ?? ''}',
              value: emp,
              onChanged: (v) => setS(() => emp = v),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Assign',
              expand: true,
              onPressed: emp == null
                  ? null
                  : () {
                      app.assignAsset(a, emp);
                      Navigator.pop(ctx);
                      showAppSnack(context, 'Asset assigned to ${app.nameOf(emp!)}.');
                    },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Asset Management',
      subtitle: 'Company equipment inventory',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Add', icon: Icons.add, compact: true, onPressed: () => _add(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final q = _query.toLowerCase();
        int count(String s) => app.assets.where((a) => a.status == s).length;
        final list = app.assets.where((a) => (_status == 'All' || a.status == _status) && (q.isEmpty || a.name.toLowerCase().contains(q) || a.serial.toLowerCase().contains(q))).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGrid(minTileWidth: 150, spacing: 10, children: [
              StatCard(label: 'Total assets', value: '${app.assets.length}', icon: Icons.inventory_2_outlined, color: AppColors.navy),
              StatCard(label: 'Assigned', value: '${count('Assigned')}', icon: Icons.person_outline, color: AppColors.info),
              StatCard(label: 'Available', value: '${count('Available')}', icon: Icons.check_circle_outline, color: AppColors.success),
              StatCard(label: 'Under repair', value: '${count('Under Repair')}', icon: Icons.build_outlined, color: AppColors.warning),
            ]),
            const Gap(16),
            SearchField(hint: 'Search by name or serial', onChanged: (v) => setState(() => _query = v)),
            const Gap(12),
            AppFilterChips<String>(options: const ['All', 'Assigned', 'Available', 'Under Repair'], selected: _status, onSelected: (v) => setState(() => _status = v)),
            const Gap(16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No assets found', icon: Icons.inventory_2_outlined))
            else
              ResponsiveGrid(minTileWidth: 340, spacing: 12, children: [
                for (final a in list)
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: assetColor(a.status).withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                          child: Icon(assetIcon(a.type), color: assetColor(a.status)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${a.type}  -  ${a.serial}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ]),
                        ),
                        StatusBadge(label: a.status, color: assetColor(a.status)),
                      ]),
                      const SizedBox(height: 10),
                      IconText(Icons.person_outline, a.assignedTo == null ? 'Unassigned' : app.nameOf(a.assignedTo!)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        if (a.status == 'Assigned')
                          AppButton(label: 'Unassign', type: AppButtonType.text, compact: true, onPressed: () {
                            app.assignAsset(a, null);
                            showAppSnack(context, 'Asset returned to inventory.');
                          })
                        else if (a.status == 'Available')
                          AppButton(label: 'Assign', icon: Icons.person_add_alt_outlined, type: AppButtonType.text, compact: true, onPressed: () => _assign(context, a)),
                        if (a.status != 'Under Repair')
                          AppButton(label: 'Send to repair', icon: Icons.build_outlined, type: AppButtonType.text, compact: true, onPressed: () {
                            app.setAssetStatus(a, 'Under Repair');
                            showAppSnack(context, 'Marked as under repair.');
                          })
                        else
                          AppButton(label: 'Mark repaired', icon: Icons.check, type: AppButtonType.text, compact: true, onPressed: () {
                            app.setAssetStatus(a, 'Available');
                            showAppSnack(context, 'Asset is available again.');
                          }),
                      ]),
                    ]),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
