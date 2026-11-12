import 'package:office_management/core/common.dart';

class QrAttendanceScreen extends StatefulWidget {
  const QrAttendanceScreen({super.key});

  @override
  State<QrAttendanceScreen> createState() => _QrAttendanceScreenState();
}

class _QrAttendanceScreenState extends State<QrAttendanceScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  bool _scanning = false;

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final msg = await context.read<AppController>().qrScan();
    if (!mounted) return;
    setState(() => _scanning = false);
    await showSuccessDialog(context, title: 'QR verified', message: msg);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'QR Attendance',
      subtitle: 'Scan the office QR code to mark attendance',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final label = switch (app.workState) {
          WorkState.notStarted => 'Scanning will check you in.',
          WorkState.working || WorkState.onBreak => 'Scanning will check you out.',
          WorkState.completed => 'Your attendance is already completed today.',
        };
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _scan,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(24)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 130, color: Colors.white.withValues(alpha:_scanning ? 0.5 : 0.12)),
                          Positioned.fill(child: Padding(padding: const EdgeInsets.all(34), child: CustomPaint(painter: _CornerPainter()))),
                          if (_scanning)
                            AnimatedBuilder(
                              animation: _line,
                              builder: (context, _) => Align(
                                alignment: Alignment(0, -0.7 + 1.4 * _line.value),
                                child: Container(margin: const EdgeInsets.symmetric(horizontal: 40), height: 3, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha:0.8), blurRadius: 12)])),
                              ),
                            ),
                          Positioned(
                            bottom: 20,
                            child: Text(_scanning ? 'Scanning...' : 'Tap to simulate scan', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(20),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const Gap(16),
                AppButton(label: _scanning ? 'Scanning...' : 'Simulate QR scan', icon: Icons.qr_code_scanner, expand: true, loading: _scanning, onPressed: _scan),
                const Gap(10),
                const Text('Demo only: a valid office QR code is simulated locally.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const l = 34.0;
    final w = size.width, h = size.height;
    canvas.drawPath(Path()..moveTo(0, l)..lineTo(0, 0)..lineTo(l, 0), p);
    canvas.drawPath(Path()..moveTo(w - l, 0)..lineTo(w, 0)..lineTo(w, l), p);
    canvas.drawPath(Path()..moveTo(0, h - l)..lineTo(0, h)..lineTo(l, h), p);
    canvas.drawPath(Path()..moveTo(w - l, h)..lineTo(w, h)..lineTo(w, h - l), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
