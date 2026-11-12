import 'package:office_management/core/common.dart';

class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  void _edit(BuildContext context, {Shift? existing}) {
    final formKey = GlobalKey<FormState>();
    final app = context.read<AppController>();
    final name = TextEditingController(text: existing?.name ?? '');
    TimeOfDay? start = existing == null ? const TimeOfDay(hour: 9, minute: 30) : TimeOfDay(hour: existing.startHour, minute: existing.startMinute);
    TimeOfDay? end = existing == null ? const TimeOfDay(hour: 18, minute: 30) : TimeOfDay(hour: existing.endHour, minute: existing.endMinute);
    int grace = existing?.graceMinutes ?? 15;

    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(existing == null ? 'New shift' : 'Edit shift', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Shift name',
                controller: name,
                validator: (v) {
                  if (v == null || v.trim().length < 2) return 'Enter a shift name';
                  final clash = app.shifts.any((s) => s != existing && s.name.toLowerCase() == v.trim().toLowerCase());
                  return clash ? 'A shift with this name exists' : null;
                },
              ),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: TimeSelector(label: 'Start time', value: start, onChanged: (t) => setS(() => start = t))),
                const SizedBox(width: 12),
                Expanded(child: TimeSelector(label: 'End time', value: end, onChanged: (t) => setS(() => end = t))),
              ]),
              const SizedBox(height: 14),
              AppDropdown<int>(label: 'Grace period', items: const [0, 5, 10, 15, 20, 30], itemLabel: (m) => '$m minutes', value: grace, onChanged: (v) => setS(() => grace = v ?? 15)),
              const SizedBox(height: 20),
              AppButton(
                label: existing == null ? 'Create shift' : 'Save changes',
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final s = start!, e = end!;
                  if (e.hour * 60 + e.minute <= s.hour * 60 + s.minute) {
                    showAppSnack(ctx, 'End time must be after start time.', error: true);
                    return;
                  }
                  app.saveShift(existing: existing, name: name.text.trim(), sh: s.hour, sm: s.minute, eh: e.hour, em: e.minute, grace: grace);
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Shift saved.');
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Shifts',
      subtitle: 'Work timings and grace periods',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'Add', icon: Icons.add, compact: true, onPressed: () => _edit(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        return ResponsiveGrid(minTileWidth: 320, spacing: 14, children: [
          for (final s in app.shifts)
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.schedule, color: AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${s.name} shift', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), tooltip: 'Edit', onPressed: () => _edit(context, existing: s)),
                ]),
                const SizedBox(height: 12),
                Text('${Fmt.hm(s.startHour, s.startMinute)}  -  ${Fmt.hm(s.endHour, s.endMinute)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 8),
                Wrap(spacing: 14, children: [
                  IconText(Icons.timer_outlined, 'Grace ${s.graceMinutes} min'),
                  IconText(Icons.people_outline, '${app.employees.where((e) => e.shift == s.name).length} employees'),
                ]),
              ]),
            ),
        ]);
      },
    );
  }
}
