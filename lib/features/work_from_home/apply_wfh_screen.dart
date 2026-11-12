import 'package:office_management/core/common.dart';

class ApplyWfhScreen extends StatefulWidget {
  const ApplyWfhScreen({super.key});

  @override
  State<ApplyWfhScreen> createState() => _ApplyWfhScreenState();
}

class _ApplyWfhScreenState extends State<ApplyWfhScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final from = _from!;
    final to = _to ?? from;
    if (to.isBefore(from)) {
      showAppSnack(context, 'End date cannot be before the start date.', error: true);
      return;
    }
    setState(() => _busy = true);
    final app = context.read<AppController>();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await app.submitWfh(from: from, to: to, reason: _reason.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    await showSuccessDialog(context, title: 'Request submitted', message: 'Your work from home request was sent to your manager.');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Request Work From Home',
      shimmer: ShimmerLayout.list,
      maxWidth: 720,
      builder: (context) {
        final app = context.watch<AppController>();
        final used = app.wfhUsedThisMonth(app.me.id);
        final today = dateOnly(DateTime.now());
        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.info.withValues(alpha:0.08), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${used.toInt()} of ${AppController.wfhMonthlyQuota.toInt()} WFH days used this month.', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                ),
                const Gap(18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DateSelector(
                        label: 'From',
                        value: _from,
                        firstDate: today,
                        lastDate: DateTime(today.year + 1, 12, 31),
                        onChanged: (d) => setState(() {
                          _from = d;
                          if (_to != null && _to!.isBefore(d)) _to = d;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DateSelector(
                        label: 'To',
                        value: _to,
                        firstDate: _from ?? today,
                        lastDate: DateTime(today.year + 1, 12, 31),
                        onChanged: (d) => setState(() => _to = d),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                AppTextField(
                  label: 'Reason',
                  controller: _reason,
                  maxLines: 4,
                  hint: 'Why do you need to work from home?',
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Please enter at least 10 characters' : null,
                ),
                const Gap(22),
                AppButton(label: 'Submit request', expand: true, loading: _busy, onPressed: _submit),
              ],
            ),
          ),
        );
      },
    );
  }
}
