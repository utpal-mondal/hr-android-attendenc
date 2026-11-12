import 'package:office_management/core/common.dart';

import '../../data/api/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn(UserRole role) async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final app = context.read<AppController>();
    final auth = context.read<AuthController>();
    auth.rememberMe = _remember;
    app.start(role); // loads mock data, shimmer shows meanwhile
    auth.signIn(role); // router redirect opens the role's home
  }

  Future<void> _apiSignIn() async {
    setState(() => _loading = true);
    final auth = context.read<AuthController>();
    final error = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    auth.rememberMe = _remember;
    if (error != null) {
      setState(() => _loading = false);
      showAppSnack(context, error, error: true);
      return;
    }
    // Role is set by login; the router redirect opens the role's home while
    // AppController loads the snapshot in the background.
    context.read<AppController>().start(auth.role!);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    if (auth.isApiMode) {
      await _apiSignIn();
      return;
    }
    final role = auth.roleForEmail(_email.text);
    if (role == null) {
      showAppSnack(context, 'Account not found. Use one of the demo accounts below.', error: true);
      return;
    }
    await _signIn(role);
  }

  void _demo(UserRole r) {
    final auth = context.read<AuthController>();
    if (auth.isApiMode) {
      _email.text = auth.seedEmailFor(r);
      _password.text = ApiConfig.seedPassword;
      _submit();
      return;
    }
    _email.text = r.demoEmail;
    _password.text = AuthController.demoPassword;
    _signIn(r);
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.width(context) >= 900;
    final form = _buildForm(context);
    return Scaffold(
      backgroundColor: wide ? Colors.white : AppColors.background,
      body: wide
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    color: AppColors.navy,
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 28),
                        const Text('Run your workplace\nfrom one place.', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 16),
                        const Text('Attendance, leave, approvals and people operations for employees, managers and HR.', style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                      ],
                    ),
                  ),
                ),
                Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: form)))),
              ],
            )
          : SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: form)))),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Responsive.width(context) < 900) ...[
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.apartment_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('OfficeHub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 28),
        ],
        const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Sign in with your corporate email to continue.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Work email',
                controller: _email,
                hint: 'name@company.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                controller: _password,
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscure: _hide,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20), onPressed: () => setState(() => _hide = !_hide)),
                validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : (v.length < 4 ? 'Password is too short' : null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(value: _remember, activeColor: AppColors.teal, onChanged: (v) => setState(() => _remember = v ?? false)),
            const Expanded(child: Text('Remember me', style: TextStyle(fontSize: 13.5))),
            TextButton(onPressed: () => context.push('/auth/forgot-password'), child: const Text('Forgot password?')),
          ],
        ),
        const SizedBox(height: 8),
        AppButton(label: 'Sign in', expand: true, loading: _loading, onPressed: _submit),
        const SizedBox(height: 28),
        Row(children: const [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('DEMO ACCESS', style: TextStyle(fontSize: 11.5, letterSpacing: 1, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),
        _demoTile(UserRole.employee, Icons.person_outline, 'Personal attendance, leave & services'),
        const SizedBox(height: 10),
        _demoTile(UserRole.manager, Icons.groups_outlined, 'Team attendance & approvals'),
        const SizedBox(height: 10),
        _demoTile(UserRole.hr, Icons.admin_panel_settings_outlined, 'Organisation administration & analytics'),
        const SizedBox(height: 14),
        Builder(builder: (context) {
          final apiMode = context.read<AuthController>().isApiMode;
          return Text(
            apiMode
                ? 'Seed password: ${ApiConfig.seedPassword}  -  server: ${ApiConfig.baseUrl}'
                : 'Demo password: ${AuthController.demoPassword} (any password works in this demo)',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          );
        }),
      ],
    );
  }

  Widget _demoTile(UserRole role, IconData icon, String desc) {
    final auth = context.read<AuthController>();
    final email = auth.isApiMode ? auth.seedEmailFor(role) : role.demoEmail;
    return AppCard(
      onTap: _loading ? null : () => _demo(role),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.teal, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(email, style: const TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
