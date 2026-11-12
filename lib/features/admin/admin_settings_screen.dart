import 'package:office_management/core/common.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _company = TextEditingController(text: 'Nexora Technologies Pvt. Ltd.');
  final _domain = TextEditingController(text: 'nexora.demo');
  String _timezone = 'Asia/Kolkata (IST)';
  int _grace = 15;
  int _radius = 100;
  bool _geofence = true;
  bool _qr = true;
  bool _autoCheckout = false;
  bool _selfie = false;
  bool _carryForward = true;
  bool _emailDigest = true;
  bool _pushAlerts = true;
  bool _twoFactor = true;
  String _session = '30 minutes';

  @override
  void dispose() {
    _company.dispose();
    _domain.dispose();
    super.dispose();
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.teal),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
          ]),
          const Gap(10),
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ]),
      );

  Widget _sw(String t, String sub, bool v, ValueChanged<bool> f) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12.5)),
        value: v,
        onChanged: f,
      );

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Settings',
      subtitle: 'Organisation-wide configuration',
      shimmer: ShimmerLayout.list,
      maxWidth: 820,
      builder: (context) {
        final auth = context.watch<AuthController>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Company', Icons.business_outlined, [
              AppTextField(label: 'Company name', controller: _company),
              const Gap(14),
              AppTextField(label: 'Email domain', controller: _domain),
              const Gap(14),
              AppDropdown<String>(label: 'Time zone', items: const ['Asia/Kolkata (IST)', 'Asia/Dubai (GST)', 'Europe/London (GMT)', 'America/New_York (EST)'], value: _timezone, onChanged: (v) => setState(() => _timezone = v ?? _timezone)),
            ]),
            _section('Attendance policy', Icons.fingerprint, [
              AppDropdown<int>(label: 'Default grace period', items: const [0, 5, 10, 15, 20, 30], itemLabel: (m) => '$m minutes', value: _grace, onChanged: (v) => setState(() => _grace = v ?? 15)),
              const Gap(14),
              AppDropdown<int>(label: 'Geofence radius', items: const [50, 100, 200, 500], itemLabel: (m) => '$m metres', value: _radius, onChanged: (v) => setState(() => _radius = v ?? 100)),
              _sw('Enforce geofence', 'Employees must be within the radius to check in', _geofence, (v) => setState(() => _geofence = v)),
              const Divider(),
              _sw('QR attendance', 'Allow QR code scanning at branch entrances', _qr, (v) => setState(() => _qr = v)),
              const Divider(),
              _sw('Auto check-out', 'Automatically check out at the end of the shift', _autoCheckout, (v) => setState(() => _autoCheckout = v)),
              const Divider(),
              _sw('Selfie verification', 'Capture a selfie during check-in', _selfie, (v) => setState(() => _selfie = v)),
            ]),
            _section('Leave policy', Icons.beach_access_outlined, [
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final q in AppController.leaveQuota.entries) StatusBadge(label: '${q.key}: ${q.value.toInt()} days', color: AppColors.purple),
              ]),
              _sw('Carry forward earned leave', 'Unused earned leave rolls over to next year', _carryForward, (v) => setState(() => _carryForward = v)),
            ]),
            _section('Notifications', Icons.notifications_none, [
              _sw('Daily email digest', 'Summary of attendance and approvals', _emailDigest, (v) => setState(() => _emailDigest = v)),
              const Divider(),
              _sw('Push alerts', 'Real-time approvals and anomalies', _pushAlerts, (v) => setState(() => _pushAlerts = v)),
            ]),
            _section('Security', Icons.shield_outlined, [
              _sw('Require two-factor authentication', 'Enforce 2FA for all HR / admin users', _twoFactor, (v) => setState(() => _twoFactor = v)),
              const Gap(8),
              AppDropdown<String>(label: 'Session timeout', items: const ['15 minutes', '30 minutes', '1 hour', '8 hours'], value: _session, onChanged: (v) => setState(() => _session = v ?? _session)),
            ]),
            _section('Appearance', Icons.text_fields, [
              const Text('Text size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Gap(8),
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
            Row(children: [
              Expanded(child: AppButton(label: 'Save settings', icon: Icons.save_outlined, onPressed: () => showAppSnack(context, 'Settings saved (demo - not persisted).'))),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Log out', icon: Icons.logout, type: AppButtonType.destructive, onPressed: () => performLogout(context))),
            ]),
          ],
        );
      },
    );
  }
}
