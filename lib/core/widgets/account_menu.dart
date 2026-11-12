import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/enums.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'dialogs.dart';

Future<void> performLogout(BuildContext context) async {
  final ok = await showConfirmDialog(context,
      title: 'Log out?', message: 'You will be returned to the login screen.', confirmLabel: 'Log out', destructive: true);
  if (!ok || !context.mounted) return;
  final app = context.read<AppController>();
  final auth = context.read<AuthController>();
  app.reset();
  auth.signOut(); // router redirect sends the user to /auth/login
}

/// Avatar popup with profile / settings / logout.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    if (!app.loaded) return const SizedBox(width: 44);
    final me = app.me;
    final role = app.role ?? UserRole.employee;
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      onSelected: (v) {
        switch (v) {
          case 'profile':
            context.go('/employee/profile');
          case 'settings':
            context.go('${role.basePath}/settings');
          case 'logout':
            performLogout(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(me.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(role.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (role == UserRole.employee) const PopupMenuItem<String>(value: 'profile', child: ListTile(dense: true, leading: Icon(Icons.person_outline), title: Text('My profile'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem<String>(value: 'settings', child: ListTile(dense: true, leading: Icon(Icons.settings_outlined), title: Text('Settings'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem<String>(value: 'logout', child: ListTile(dense: true, leading: Icon(Icons.logout, color: AppColors.danger), title: Text('Log out', style: TextStyle(color: AppColors.danger)), contentPadding: EdgeInsets.zero)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AvatarWidget(name: me.name, size: 38),
      ),
    );
  }
}
