import 'package:office_management/core/common.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  void _add(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final city = TextEditingController();
    final address = TextEditingController();
    final hours = TextEditingController(text: '09:30 AM - 06:30 PM');
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New branch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppTextField(label: 'Branch name', controller: name, validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a branch name' : null),
            const SizedBox(height: 14),
            AppTextField(label: 'City', controller: city, validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a city' : null),
            const SizedBox(height: 14),
            AppTextField(label: 'Address', controller: address, maxLines: 2, validator: (v) => (v == null || v.trim().length < 6) ? 'Enter an address' : null),
            const SizedBox(height: 14),
            AppTextField(label: 'Working hours', controller: hours),
            const SizedBox(height: 20),
            AppButton(
              label: 'Create branch',
              expand: true,
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                app.addBranch(name: name.text.trim(), city: city.text.trim(), address: address.text.trim(), hours: hours.text.trim());
                Navigator.pop(ctx);
                showAppSnack(context, 'Branch created.');
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
      title: 'Branches',
      subtitle: 'Office locations and working hours',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Add', icon: Icons.add, compact: true, onPressed: () => _add(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        return ResponsiveGrid(minTileWidth: 340, spacing: 14, children: [
          for (final b in app.branches)
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.navy.withValues(alpha:0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.apartment, color: AppColors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(b.city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ]),
                  ),
                  StatusBadge(label: '${app.employeeCountAt(b.name)} staff', color: AppColors.info),
                ]),
                const SizedBox(height: 12),
                IconText(Icons.location_on_outlined, b.address),
                const SizedBox(height: 6),
                IconText(Icons.schedule, b.workingHours),
              ]),
            ),
        ]);
      },
    );
  }
}
