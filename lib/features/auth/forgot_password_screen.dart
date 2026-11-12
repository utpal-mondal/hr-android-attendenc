import 'package:office_management/core/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = context.read<AuthController>().api;
    if (api != null) {
      try {
        await api.forgotPassword(_email.text.trim());
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        showAppSnack(context, 'Could not send the reset link. Please try again.', error: true);
        return;
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _sent
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha:0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 42),
                      ),
                      const SizedBox(height: 22),
                      const Text('Check your inbox', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Text(
                          'We have sent password reset instructions to ${_email.text.trim()}.${context.read<AuthController>().isApiMode ? '' : ' (Simulated in this demo.)'}',
                          textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 26),
                      AppButton(label: 'Back to sign in', expand: true, onPressed: () => context.go('/auth/login')),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Forgot password?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Enter your work email and we will send you a reset link.', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Work email',
                          controller: _email,
                          hint: 'name@company.com',
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        AppButton(label: 'Send reset link', expand: true, loading: _loading, onPressed: _submit),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
