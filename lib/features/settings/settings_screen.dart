import 'package:office_management/core/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: title),
          AppCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Column(children: children)),
        ]),
      );

  Widget _switch(String title, String sub, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12.5)),
        value: value,
        onChanged: onChanged,
      );

  void _changePassword(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    showAppSheet<void>(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Change password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppTextField(label: 'Current password', controller: current, obscure: true, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 14),
            AppTextField(label: 'New password', controller: next, obscure: true, validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null),
            const SizedBox(height: 14),
            AppTextField(label: 'Confirm new password', controller: confirm, obscure: true, validator: (v) => v != next.text ? 'Passwords do not match' : null),
            const SizedBox(height: 20),
            AppButton(
              label: 'Update password',
              expand: true,
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                showAppSnack(context, 'Password updated (demo).');
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
      title: 'Settings',
      shimmer: ShimmerLayout.list,
      maxWidth: 760,
      builder: (context) {
        final app = context.watch<AppController>();
        final auth = context.watch<AuthController>();
        final me = app.me;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(children: [
                AvatarWidget(name: me.name, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(me.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    StatusBadge(label: (app.role ?? UserRole.employee).label, color: AppColors.teal),
                  ]),
                ),
              ]),
            ),
            const Gap(20),
            _section('Notifications', [
              _switch('Push notifications', 'Approvals, reminders and announcements', auth.pushNotifications, (v) => auth.update(() => auth.pushNotifications = v)),
              const Divider(),
              _switch('Email alerts', 'Daily summary and important updates', auth.emailAlerts, (v) => auth.update(() => auth.emailAlerts = v)),
              const Divider(),
              _switch('Attendance reminders', 'Remind me to check in and out', auth.attendanceReminders, (v) => auth.update(() => auth.attendanceReminders = v)),
            ]),
            _section('Security', [
              _switch('Biometric lock', 'Require fingerprint / face to open the app', auth.biometricLock, (v) => auth.update(() => auth.biometricLock = v)),
              const Divider(),
              _switch('Two-factor authentication', 'Extra verification at sign in', auth.twoFactor, (v) => auth.update(() => auth.twoFactor = v)),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline, color: AppColors.teal),
                title: const Text('Change password', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context),
              ),
            ]),
            _section('Preferences', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AppDropdown<String>(
                  label: 'Language',
                  items: const ['English', 'Hindi', 'Bengali'],
                  value: auth.language,
                  onChanged: (v) => auth.update(() => auth.language = v ?? 'English'),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Text size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0.9, label: Text('Small')),
                      ButtonSegment(value: 1.0, label: Text('Normal')),
                      ButtonSegment(value: 1.15, label: Text('Large')),
                    ],
                    selected: {auth.textScale},
                    onSelectionChanged: (s) => auth.update(() => auth.textScale = s.first),
                  ),
                ]),
              ),
            ]),
            _section('About', [
              const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.info_outline, color: AppColors.teal), title: Text('OfficeHub demo'), subtitle: Text('Version 1.0.0 - static demo data')),
              if (app.role == UserRole.employee) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline, color: AppColors.teal),
                  title: const Text('Help & support', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/employee/help'),
                ),
              ],
            ]),
            AppButton(label: 'Log out', icon: Icons.logout, type: AppButtonType.destructive, expand: true, onPressed: () => performLogout(context)),
          ],
        );
      },
    );
  }
}
