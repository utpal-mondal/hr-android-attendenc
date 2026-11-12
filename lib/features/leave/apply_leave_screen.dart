import 'package:office_management/core/common.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _type;
  DateTime? _from;
  DateTime? _to;
  bool _half = false;
  bool _attachment = false;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  double _days() {
    if (_from == null) return 0;
    if (_half) return 0.5;
    final to = _to ?? _from!;
    return LeaveRequest(id: 'x', employeeId: 'x', type: 'x', from: _from!, to: to, reason: '', appliedOn: DateTime.now()).days;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppController>();
    final from = _from!;
    final to = _half ? from : (_to ?? from);
    if (to.isBefore(from)) {
      showAppSnack(context, 'End date cannot be before the start date.', error: true);
      return;
    }
    LeaveBalance? bal;
    for (final b in app.balancesFor(app.me.id)) {
      if (b.type == _type) {
        bal = b;
        break;
      }
    }
    // When the server reports no balance row for this type, skip the local
    // check — the API validates the balance itself on submit.
    if (bal != null && _days() > bal.remaining) {
      showAppSnack(context, 'Insufficient ${bal.type} balance (${bal.remaining} day(s) left).', error: true);
      return;
    }
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await app.submitLeave(type: _type!, from: from, to: to, halfDay: _half, reason: _reason.text.trim(), attachment: _attachment);
    if (!mounted) return;
    setState(() => _busy = false);
    await showSuccessDialog(context, title: 'Request submitted', message: 'Your $_type request for ${_days() % 1 == 0 ? _days().toInt() : _days()} day(s) was sent to your manager for approval.');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Apply for Leave',
      shimmer: ShimmerLayout.list,
      maxWidth: 720,
      builder: (context) {
        final app = context.watch<AppController>();
        final balances = app.balancesFor(app.me.id);
        final today = dateOnly(DateTime.now());
        LeaveBalance? bal;
        if (_type != null) {
          for (final b in balances) {
            if (b.type == _type) {
              bal = b;
              break;
            }
          }
        }
        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppDropdown<String>(
                  label: 'Leave type',
                  hint: 'Select leave type',
                  items: app.leaveTypes,
                  value: _type,
                  validator: (v) => v == null ? 'Please select a leave type' : null,
                  onChanged: (v) => setState(() => _type = v),
                ),
                if (bal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Available balance: ${bal.remaining % 1 == 0 ? bal.remaining.toInt() : bal.remaining} day(s)', style: const TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w600)),
                  ),
                const Gap(16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Half day', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Apply for half a day only'),
                  value: _half,
                  onChanged: (v) => setState(() => _half = v),
                ),
                const Gap(8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DateSelector(
                        label: _half ? 'Date' : 'From',
                        value: _from,
                        firstDate: DateTime(today.year, today.month - 1, 1),
                        lastDate: DateTime(today.year + 1, 12, 31),
                        onChanged: (d) => setState(() {
                          _from = d;
                          if (_to != null && _to!.isBefore(d)) _to = d;
                        }),
                      ),
                    ),
                    if (!_half) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateSelector(
                          label: 'To',
                          value: _to,
                          firstDate: _from ?? DateTime(today.year, today.month - 1, 1),
                          lastDate: DateTime(today.year + 1, 12, 31),
                          onChanged: (d) => setState(() => _to = d),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_from != null)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('Duration: ${_days() % 1 == 0 ? _days().toInt() : _days()} working day(s) (weekends excluded)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ]),
                  ),
                const Gap(16),
                AppTextField(
                  label: 'Reason',
                  controller: _reason,
                  maxLines: 4,
                  hint: 'Briefly describe the reason for your leave',
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Please enter at least 10 characters' : null,
                ),
                const Gap(14),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _attachment = !_attachment),
                  icon: Icon(_attachment ? Icons.check_circle : Icons.attach_file, size: 18),
                  label: Text(_attachment ? 'medical_certificate.pdf attached (tap to remove)' : 'Attach document (optional)'),
                  style: OutlinedButton.styleFrom(foregroundColor: _attachment ? AppColors.success : AppColors.navy, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
