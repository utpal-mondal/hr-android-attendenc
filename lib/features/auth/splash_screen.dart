import 'package:office_management/core/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  /// Set when the saved session could not be checked (server unreachable).
  String? _offlineError;

  @override
  void initState() {
    super.initState();
    // Kick off session restore immediately so it overlaps the animation.
    final restore = _tryRestore();
    Future<void>.delayed(const Duration(milliseconds: 2300), () => _continue(restore));
  }

  Future<bool?> _tryRestore() async {
    // Grab the controllers now: a successful restore makes the router leave
    // this screen at once, so it may be unmounted by the time we continue.
    final auth = context.read<AuthController>();
    final app = context.read<AppController>();
    try {
      final restored = await auth.restoreSession();
      // Start loading the data right away (not after the splash delay); the
      // home page shows its loading shimmer until it arrives.
      if (restored && auth.role != null) app.start(auth.role!);
      return restored;
    } catch (e) {
      return null; // unreachable server: keep the token, offer a retry
    }
  }

  Future<void> _continue(Future<bool?> restore) async {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    // In API mode, a stored token restores the session; the router redirect
    // then sends us straight to the role's home.
    if (auth.isApiMode) {
      final restored = await restore;
      if (!mounted) return;
      if (restored == null) {
        setState(() => _offlineError = 'Cannot reach the server. Check your internet connection and try again.');
        return;
      }
      if (restored) return; // data load already started in _tryRestore
    }
    await auth.loadPreferences();
    if (!mounted) return;
    context.go(auth.onboardingSeen ? '/auth/login' : '/auth/onboarding');
  }

  void _retry() {
    setState(() => _offlineError = null);
    _continue(_tryRestore());
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
                if (_offlineError == null)
                  const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white54))
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_offlineError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
