import 'package:office_management/core/common.dart';
import 'package:office_management/features/employees/employee_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Lets the employee update their phone number (`PUT /profile`). Other
  /// details (department, address, ...) are managed by HR.
  void _edit(BuildContext context, Employee e) {
    final formKey = GlobalKey<FormState>();
    final phone = TextEditingController(text: e.phone);
    final api = context.read<AuthController>().api;
    var busy = false;
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Other details such as department and address are updated by HR.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone',
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.call_outlined,
                  validator: (v) => (v == null || v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Save changes',
                  expand: true,
                  loading: busy,
                  onPressed: busy
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final value = phone.text.trim();
                          setS(() => busy = true);
                          try {
                            await api?.updateProfile(phone: value);
                            e.phone = value;
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              context.read<AppController>().refreshUi();
                              showAppSnack(context, 'Phone number updated.');
                            }
                          } catch (err) {
                            if (!ctx.mounted) return;
                            setS(() => busy = false);
                            showAppSnack(ctx, err.toString(), error: true);
                          }
                        },
                ),
              ],
            ),
          ),
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
