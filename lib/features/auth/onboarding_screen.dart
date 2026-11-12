import 'package:office_management/core/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (Icons.fingerprint, 'Smart attendance', 'Check in, take breaks and check out in a single tap with simulated location verification and QR support.'),
    (Icons.event_available_outlined, 'Leave & WFH made simple', 'Apply for leave or work from home, track balances and get approvals from your manager in real time.'),
    (Icons.insights_outlined, 'Insights for every role', 'Employees, managers and HR each get a tailored workspace with dashboards, reports and approvals.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<AuthController>().completeOnboarding();
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AppButton(label: 'Skip', type: AppButtonType.text, compact: true, onPressed: _finish),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final s = _slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.teal.withValues(alpha:0.18), AppColors.navy.withValues(alpha:0.08)]),
                              ),
                              child: Icon(s.$1, size: 84, color: AppColors.teal),
                            ),
                            const SizedBox(height: 40),
                            Text(s.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            Text(s.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(color: i == _index ? AppColors.teal : AppColors.border, borderRadius: BorderRadius.circular(8)),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppButton(
                    label: last ? 'Get Started' : 'Next',
                    expand: true,
                    onPressed: () {
                      if (last) {
                        _finish();
                      } else {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
