import 'package:office_management/core/common.dart';

class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key});

  void _add(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    DateTime? date;
    String type = 'Public';
    final app = context.read<AppController>();
    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add holiday', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              AppTextField(label: 'Holiday name', controller: name, validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a name' : null),
              const SizedBox(height: 14),
              DateSelector(label: 'Date', value: date, firstDate: DateTime(DateTime.now().year - 1), lastDate: DateTime(DateTime.now().year + 2, 12, 31), onChanged: (d) => setS(() => date = d)),
              const SizedBox(height: 14),
              AppDropdown<String>(label: 'Type', items: const ['Public', 'National', 'Festival', 'Optional'], value: type, onChanged: (v) => setS(() => type = v ?? 'Public')),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add holiday',
                expand: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  if (app.holidays.any((h) => sameDay(h.date, date!))) {
                    showAppSnack(ctx, 'A holiday already exists on this date.', error: true);
                    return;
                  }
                  app.addHoliday(name.text.trim(), date!, type);
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Holiday added.');
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String t) => switch (t) {
        'National' => AppColors.navy,
        'Festival' => AppColors.purple,
        'Optional' => AppColors.textSecondary,
        _ => AppColors.teal,
      };

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Holiday Calendar',
      subtitle: 'Company holidays',
      shimmer: ShimmerLayout.list,
      maxWidth: 820,
      actions: [
        AppButton(label: 'Add', icon: Icons.add, compact: true, onPressed: () => _add(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final list = [...app.holidays]..sort((a, b) => a.date.compareTo(b.date));
        if (list.isEmpty) return const EmptyState(title: 'No holidays configured', icon: Icons.celebration_outlined);
        final groups = <String, List<Holiday>>{};
        for (final h in list) {
          groups.putIfAbsent(Fmt.monthYear(h.date), () => []).add(h);
        }
        final today = dateOnly(DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in groups.entries) ...[
              SectionHeader(title: g.key),
              for (final h in g.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    color: h.date.isBefore(today) ? const Color(0xFFFAFAFB) : Colors.white,
                    child: Row(children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: _typeColor(h.type).withValues(alpha:0.10), borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          Text('${h.date.day}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _typeColor(h.type))),
                          Text(Fmt.weekday(h.date), style: TextStyle(fontSize: 11, color: _typeColor(h.type))),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(h.name, style: TextStyle(fontWeight: FontWeight.w700, color: h.date.isBefore(today) ? AppColors.textSecondary : AppColors.textPrimary))),
                      StatusBadge(label: h.type, color: _typeColor(h.type)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        tooltip: 'Remove',
                        onPressed: () async {
                          final ok = await showConfirmDialog(context, title: 'Remove holiday?', message: '${h.name} will be removed from the calendar.', confirmLabel: 'Remove', destructive: true);
                          if (ok) {
                            app.removeHoliday(h);
                            if (context.mounted) showAppSnack(context, 'Holiday removed.');
                          }
                        },
                      ),
                    ]),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
