import 'package:office_management/core/common.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Keys stored via GET/PUT /admin/settings. The two attendance.geofence_*
  // keys are enforced by the API on every check-in / check-out.
  static const _kCompany = 'company.name';
  static const _kDomain = 'company.email_domain';
  static const _kTimezone = 'company.timezone';
  static const _kGrace = 'attendance.default_grace_minutes';
  static const _kGeofence = 'attendance.geofence_enforced';
  static const _kRadius = 'attendance.geofence_radius_meters';
  static const _kCarryForward = 'leave.carry_forward_earned';
  static const _kEmailDigest = 'notifications.email_digest';
  static const _kPushAlerts = 'notifications.push_alerts';

  static const _timezones = ['Asia/Kolkata', 'Asia/Dubai', 'Europe/London', 'America/New_York', 'UTC'];
  static const _graces = [0, 5, 10, 15, 20, 30];
  static const _radii = [50, 100, 200, 500, 1000];

  final _company = TextEditingController();
  final _domain = TextEditingController();
  String _timezone = 'Asia/Kolkata';
  int _grace = 15;
  int _radius = 100;
  bool _geofence = true;
  bool _carryForward = true;
  bool _emailDigest = true;
  bool _pushAlerts = true;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _bool(String? v, bool fallback) => v == null || v.isEmpty ? fallback : (v == '1' || v.toLowerCase() == 'true');

  int _int(String? v, int fallback, List<int> allowed) {
    final i = int.tryParse(v ?? '');
    return i != null && allowed.contains(i) ? i : fallback;
  }

  Future<void> _load() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final s = await context.read<AppController>().loadCompanySettings();
      if (!mounted) return;
      setState(() {
        _company.text = s[_kCompany] ?? '';
        _domain.text = s[_kDomain] ?? '';
        _timezone = _timezones.contains(s[_kTimezone]) ? s[_kTimezone]! : 'Asia/Kolkata';
        _grace = _int(s[_kGrace], 15, _graces);
        _radius = _int(s[_kRadius], 100, _radii);
        _geofence = _bool(s[_kGeofence], true);
        _carryForward = _bool(s[_kCarryForward], true);
        _emailDigest = _bool(s[_kEmailDigest], true);
        _pushAlerts = _bool(s[_kPushAlerts], true);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<AppController>().saveCompanySettings({
      _kCompany: _company.text.trim(),
      _kDomain: _domain.text.trim(),
      _kTimezone: _timezone,
      _kGrace: _grace,
      _kGeofence: _geofence.toString(),
      _kRadius: _radius,
      _kCarryForward: _carryForward.toString(),
      _kEmailDigest: _emailDigest.toString(),
      _kPushAlerts: _pushAlerts.toString(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) showAppSnack(context, 'Settings saved.');
  }

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
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700))),
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
        if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: AppCard(
                  child: Row(children: [
                    const Icon(Icons.lock_outline, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_loadError!, style: const TextStyle(fontWeight: FontWeight.w600))),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ),
              ),
            _section('Company', Icons.business_outlined, [
              AppTextField(label: 'Company name', controller: _company),
              const Gap(14),
              AppTextField(label: 'Email domain', controller: _domain),
              const Gap(14),
              AppDropdown<String>(label: 'Time zone', items: _timezones, value: _timezone, onChanged: (v) => setState(() => _timezone = v ?? _timezone)),
            ]),
            _section('Attendance policy', Icons.fingerprint, [
              AppDropdown<int>(label: 'Default grace period', items: _graces, itemLabel: (m) => '$m minutes', value: _grace, onChanged: (v) => setState(() => _grace = v ?? 15)),
              const Gap(14),
              AppDropdown<int>(label: 'Default geofence radius', items: _radii, itemLabel: (m) => '$m metres', value: _radius, onChanged: (v) => setState(() => _radius = v ?? 100)),
              const Gap(6),
              const Text('Used for branches without their own radius. Set each office location under Branches.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              _sw('Enforce geofence', 'Employees must be within the radius to check in or out', _geofence, (v) => setState(() => _geofence = v)),
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
              Expanded(child: AppButton(label: 'Save settings', icon: Icons.save_outlined, loading: _saving, onPressed: _loadError == null ? _save : null)),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Log out', icon: Icons.logout, type: AppButtonType.destructive, onPressed: () => performLogout(context))),
            ]),
          ],
        );
      },
    );
  }
}
