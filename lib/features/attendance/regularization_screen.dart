import 'package:office_management/core/common.dart';

class RegularizationScreen extends StatefulWidget {
  const RegularizationScreen({super.key, this.initialDate});
  final String? initialDate;

  @override
  State<RegularizationScreen> createState() => _RegularizationScreenState();
}

class _RegularizationScreenState extends State<RegularizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  DateTime? _date;
  TimeOfDay? _in = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay? _out = const TimeOfDay(hour: 18, minute: 30);
  bool _attachment = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _date = DateTime.tryParse(widget.initialDate!);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final i = _in!, o = _out!;
    if (o.hour * 60 + o.minute <= i.hour * 60 + i.minute) {
      showAppSnack(context, 'Check-out time must be after check-in time.', error: true);
      return;
    }
    setState(() => _busy = true);
    final d = _date!;
    await context.read<AppController>().submitRegularization(
          date: d,
          checkIn: DateTime(d.year, d.month, d.day, i.hour, i.minute),
          checkOut: DateTime(d.year, d.month, d.day, o.hour, o.minute),
          reason: _reason.text.trim(),
          attachment: _attachment,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _date = null;
      _attachment = false;
      _reason.clear();
    });
    _formKey.currentState?.reset();
    showAppSnack(context, 'Regularization submitted and pending approval.');
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Attendance Regularization',
      subtitle: 'Correct a missed or incorrect check-in / check-out',
      builder: (context) {
        final app = context.watch<AppController>();
        final history = app.regularizationsFor(app.me.id);
        final today = dateOnly(DateTime.now());

        final form = AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New request', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Gap(16),
                DateSelector(
                  label: 'Date to correct',
                  value: _date,
                  firstDate: DateTime(today.year, today.month - 3, 1),
                  lastDate: today,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const Gap(14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: TimeSelector(label: 'Check-in', value: _in, onChanged: (t) => setState(() => _in = t))),
                    const SizedBox(width: 12),
                    Expanded(child: TimeSelector(label: 'Check-out', value: _out, onChanged: (t) => setState(() => _out = t))),
                  ],
                ),
                const Gap(14),
                AppTextField(
                  label: 'Reason',
                  controller: _reason,
                  hint: 'Explain why the correction is needed',
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Please enter at least 10 characters' : null,
                ),
                const Gap(14),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _attachment = !_attachment),
                  icon: Icon(_attachment ? Icons.check_circle : Icons.attach_file, size: 18),
                  label: Text(_attachment ? 'proof_screenshot.png attached (tap to remove)' : 'Attach supporting document'),
                  style: OutlinedButton.styleFrom(foregroundColor: _attachment ? AppColors.success : AppColors.navy, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const Gap(20),
                AppButton(label: 'Submit request', expand: true, loading: _busy, onPressed: _submit),
              ],
            ),
          ),
        );

        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'My requests'),
            if (history.isEmpty)
              const AppCard(child: EmptyState(title: 'No requests yet', message: 'Submitted corrections will show up here.', icon: Icons.edit_calendar_outlined))
            else
              for (final r in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(Fmt.fullDate(r.date), style: const TextStyle(fontWeight: FontWeight.w700))),
                          requestBadge(r.status),
                        ]),
                        const Gap(6),
                        Text('${Fmt.time(r.requestedIn)}  -  ${Fmt.time(r.requestedOut)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.teal)),
                        const Gap(6),
                        Text(r.reason, style: const TextStyle(fontSize: 13.5)),
                        const Gap(6),
                        Wrap(spacing: 14, children: [
                          IconText(Icons.schedule, 'Applied ${Fmt.dateShort(r.appliedOn)}'),
                          if (r.hasAttachment) const IconText(Icons.attach_file, 'Attachment'),
                        ]),
                      ],
                    ),
                  ),
                ),
          ],
        );
        return TwoColumn(left: form, right: list, leftFlex: 1, rightFlex: 1);
      },
    );
  }
}
