import 'dart:async';

import 'package:office_management/core/common.dart';

/// Re-renders every second to show a live working timer.
class LiveDuration extends StatefulWidget {
  const LiveDuration({super.key, required this.compute, this.style});
  final Duration Function() compute;
  final TextStyle? style;

  @override
  State<LiveDuration> createState() => _LiveDurationState();
}

class _LiveDurationState extends State<LiveDuration> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(Fmt.clock(widget.compute()), style: widget.style);
}

Future<void> doCheckIn(BuildContext context) async {
  final app = context.read<AppController>();
  final ok = await runLocationVerification(context, office: app.me.branch);
  if (!ok || !context.mounted) return;
  await app.checkIn();
  if (!context.mounted) return;
  final a = app.myToday;
  await showSuccessDialog(
    context,
    title: 'Checked in',
    message: 'You checked in at ${Fmt.time(a?.checkIn)} and are marked ${a?.status.label ?? 'Present'}. Have a productive day!',
  );
}

Future<void> doCheckOut(BuildContext context) async {
  final app = context.read<AppController>();
  final a = app.myToday;
  final ok = await showConfirmDialog(
    context,
    title: 'Check out now?',
    message: 'You have worked ${Fmt.duration(a?.worked ?? Duration.zero)} today. Your day will be marked as completed.',
    confirmLabel: 'Check out',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  await app.checkOut();
  if (!context.mounted) return;
  final r = app.myToday;
  await showSuccessDialog(
    context,
    title: 'Day completed',
    message: 'Checked out at ${Fmt.time(r?.checkOut)}. Total working time: ${Fmt.duration(r?.worked ?? Duration.zero)}.',
  );
}

/// Today's work status + primary attendance actions (used on dashboard and attendance page).
class WorkStatusPanel extends StatelessWidget {
  const WorkStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final state = app.workState;
    final today = app.myToday;
    final shift = app.shiftOf(app.me);
    final (label, color) = switch (state) {
      WorkState.notStarted => ('Not checked in', const Color(0xFFFEC84B)),
      WorkState.working => ('Working', const Color(0xFF32D583)),
      WorkState.onBreak => ('On break', const Color(0xFFFDB022)),
      WorkState.completed => ('Day completed', const Color(0xFF84CAFF)),
    };

    Widget timer;
    if (today == null || state == WorkState.notStarted) {
      timer = const Text('00:00:00', style: TextStyle(color: Colors.white38, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 1));
    } else if (state == WorkState.completed) {
      timer = Text(Fmt.clock(today.worked), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 1));
    } else {
      timer = LiveDuration(
        compute: () => today.worked,
        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 1),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [AppColors.navy, Color(0xFF1B3A57)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
              const Spacer(),
              Text(Fmt.fullDate(DateTime.now()).split(',').last.trim(), style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Working duration', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
          const SizedBox(height: 2),
          timer,
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _info('Check-in', Fmt.time(today?.checkIn)),
              _info('Check-out', Fmt.time(today?.checkOut)),
              _info('Breaks', today == null ? '--' : Fmt.duration(today.breakTime)),
              _info('Shift', '${Fmt.hm(shift.startHour, shift.startMinute)} - ${Fmt.hm(shift.endHour, shift.endMinute)}'),
            ],
          ),
          const SizedBox(height: 18),
          _actions(context, state),
        ],
      ),
    );
  }

  Widget _info(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _light(String label, IconData icon, VoidCallback onTap) => FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.navy,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _ghost(String label, IconData icon, VoidCallback onTap, {bool danger = false}) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? const Color(0xFFFDA29B) : Colors.white,
          side: BorderSide(color: danger ? const Color(0xFFFDA29B) : Colors.white38),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _actions(BuildContext context, WorkState state) {
    final app = context.read<AppController>();
    switch (state) {
      case WorkState.notStarted:
        return Wrap(spacing: 10, runSpacing: 10, children: [
          _light('Check In', Icons.login_rounded, () => doCheckIn(context)),
          _ghost('Scan QR', Icons.qr_code_scanner, () => context.push('/employee/attendance/qr')),
        ]);
      case WorkState.working:
        return Wrap(spacing: 10, runSpacing: 10, children: [
          _light('Start Break', Icons.free_breakfast_outlined, () {
            app.startBreak();
            showAppSnack(context, 'Break started. Enjoy!');
          }),
          _ghost('Check Out', Icons.logout_rounded, () => doCheckOut(context), danger: true),
        ]);
      case WorkState.onBreak:
        return Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _light('End Break', Icons.play_arrow_rounded, () {
            app.endBreak();
            showAppSnack(context, 'Welcome back! Status: Working');
          }),
          LiveDuration(
            compute: () => app.myToday?.breaks.last.duration ?? Duration.zero,
            style: const TextStyle(color: Color(0xFFFDB022), fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const Text('on break', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
        ]);
      case WorkState.completed:
        return Row(children: const [
          Icon(Icons.check_circle, color: Color(0xFF32D583), size: 20),
          SizedBox(width: 8),
          Expanded(child: Text("You're all done for today. See you tomorrow!", style: TextStyle(color: Colors.white70))),
        ]);
    }
  }
}
