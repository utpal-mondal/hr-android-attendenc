import 'package:office_management/core/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  late final Future<bool> _restore;

  @override
  void initState() {
    super.initState();
    // Kick off session restore immediately so it overlaps the animation.
    _restore = context.read<AuthController>().restoreSession();
    Future<void>.delayed(const Duration(milliseconds: 2300), () async {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      // In API mode, a stored token restores the session; the router redirect
      // then sends us straight to the role's home.
      if (auth.isApiMode && await _restore) {
        if (!mounted) return;
        context.read<AppController>().start(auth.role!);
        return;
      }
      if (!mounted) return;
      context.go(auth.onboardingSeen ? '/auth/login' : '/auth/onboarding');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(anim),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(26)),
                  child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 22),
                const Text('OfficeHub', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                const SizedBox(height: 6),
                const Text('Office Management & Attendance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 40),
                const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
