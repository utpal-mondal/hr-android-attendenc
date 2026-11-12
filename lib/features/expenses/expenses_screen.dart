import 'package:office_management/core/common.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  void _newClaim(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    String? category;
    DateTime? date;
    bool receipt = false;

    showAppSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New expense claim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                AppTextField(label: 'Title', controller: title, hint: 'e.g. Client visit cab fare', validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a title' : null),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Category',
                      items: context.read<AppController>().expenseCategories,
                      value: category,
                      validator: (v) => v == null ? 'Select category' : null,
                      onChanged: (v) => setS(() => category = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Amount (INR)',
                      controller: amount,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                DateSelector(label: 'Expense date', value: date, lastDate: DateTime.now(), onChanged: (d) => setS(() => date = d)),
                const SizedBox(height: 14),
                AppTextField(label: 'Notes (optional)', controller: notes, maxLines: 2),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => setS(() => receipt = !receipt),
                  icon: Icon(receipt ? Icons.check_circle : Icons.receipt_outlined, size: 18),
                  label: Text(receipt ? 'receipt.jpg attached (tap to remove)' : 'Attach receipt'),
                  style: OutlinedButton.styleFrom(foregroundColor: receipt ? AppColors.success : AppColors.navy, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Submit claim',
                  expand: true,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    context.read<AppController>().submitExpense(
                          title: title.text.trim(),
                          category: category!,
                          amount: double.parse(amount.text.trim()),
                          date: date!,
                          receipt: receipt,
                          notes: notes.text.trim(),
                        );
                    Navigator.pop(ctx);
                    showAppSnack(context, 'Expense claim submitted for approval.');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Expenses',
      subtitle: 'Claims and reimbursements',
      shimmer: ShimmerLayout.list,
      actions: [
        AppButton(label: 'New claim', icon: Icons.add, compact: true, onPressed: () => _newClaim(context)),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.expensesFor(app.me.id);
        double sum(bool Function(Expense) f) => list.where(f).fold<double>(0, (a, b) => a + b.amount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGrid(minTileWidth: 180, spacing: 12, children: [
              StatCard(label: 'Total claimed', value: Fmt.money(sum((e) => true)), icon: Icons.receipt_long_outlined, color: AppColors.navy),
              StatCard(label: 'Pending', value: Fmt.money(sum((e) => e.status == 'Pending')), icon: Icons.hourglass_top_rounded, color: AppColors.warning),
              StatCard(label: 'Reimbursed', value: Fmt.money(sum((e) => e.status == 'Reimbursed' || e.status == 'Approved')), icon: Icons.check_circle_outline, color: AppColors.success),
            ]),
            const Gap(20),
            const SectionHeader(title: 'My claims'),
            if (list.isEmpty)
              AppCard(child: EmptyState(title: 'No expense claims', icon: Icons.receipt_long_outlined, actionLabel: 'New claim', onAction: () => _newClaim(context)))
            else
              ResponsiveGrid(minTileWidth: 440, spacing: 12, children: [for (final e in list) ExpenseCard(expense: e)]),
          ],
        );
      },
    );
  }
}
