import 'package:office_management/core/common.dart';
import 'package:office_management/features/employees/employee_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _edit(BuildContext context, Employee e) {
    final phone = TextEditingController(text: e.phone);
    final address = TextEditingController(text: e.address);
    showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppTextField(label: 'Phone', controller: phone, keyboardType: TextInputType.phone, prefixIcon: Icons.call_outlined),
            const SizedBox(height: 14),
            AppTextField(label: 'Address', controller: address, maxLines: 2, prefixIcon: Icons.home_outlined),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save changes',
              expand: true,
              onPressed: () {
                Navigator.pop(ctx);
                showAppSnack(context, 'Profile update request sent to HR (demo).');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'My Profile',
      shimmer: ShimmerLayout.list,
      actions: [
        Consumer<AppController>(
          builder: (context, app, _) => app.loaded
              ? AppButton(label: 'Edit', icon: Icons.edit_outlined, compact: true, type: AppButtonType.secondary, onPressed: () => _edit(context, app.me))
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final me = app.me;
        final assets = app.assetsFor(me.id);
        return EmployeeProfileBody(
          employee: me,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Quick links'),
              ResponsiveGrid(minTileWidth: 220, spacing: 10, children: [
                _link(context, Icons.folder_outlined, 'My documents', '/employee/documents'),
                _link(context, Icons.payments_outlined, 'Payslips', '/employee/payslips'),
                _link(context, Icons.laptop_mac, '${assets.length} assigned assets', '/employee/assets'),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _link(BuildContext context, IconData icon, String label, String path) => AppCard(
        onTap: () => context.go(path),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
      );
}
