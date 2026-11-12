import 'package:office_management/core/common.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  String _status = 'Pending';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Expense Claims',
      subtitle: 'Review and reimburse employee expenses',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final all = [...app.expenses]..sort((a, b) => b.date.compareTo(a.date));
        double sum(bool Function(Expense) f) => all.where(f).fold<double>(0, (a, b) => a + b.amount);
        final list = all.where((e) => _status == 'All' || e.status == _status).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGrid(minTileWidth: 180, spacing: 12, children: [
              StatCard(label: 'Awaiting approval', value: Fmt.money(sum((e) => e.status == 'Pending')), icon: Icons.hourglass_top_rounded, color: AppColors.warning),
              StatCard(label: 'Approved', value: Fmt.money(sum((e) => e.status == 'Approved')), icon: Icons.check_circle_outline, color: AppColors.success),
              StatCard(label: 'Reimbursed', value: Fmt.money(sum((e) => e.status == 'Reimbursed')), icon: Icons.account_balance_wallet_outlined, color: AppColors.teal),
            ]),
            const Gap(18),
            AppFilterChips<String>(options: const ['Pending', 'Approved', 'Reimbursed', 'Rejected', 'All'], selected: _status, onSelected: (v) => setState(() => _status = v)),
            const Gap(16),
            if (list.isEmpty)
              const AppCard(child: EmptyState(title: 'No claims', message: 'Nothing to show for this status.', icon: Icons.receipt_long_outlined))
            else
              ResponsiveGrid(minTileWidth: 440, spacing: 12, children: [
                for (final e in list)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpenseCard(
                        expense: e,
                        employeeName: app.nameOf(e.employeeId),
                        onApprove: () {
                          app.reviewExpense(e, 'Approved');
                          showAppSnack(context, 'Expense approved.');
                        },
                        onReject: () async {
                          final ok = await showConfirmDialog(context, title: 'Reject claim?', message: '${app.nameOf(e.employeeId)} will be notified.', confirmLabel: 'Reject', destructive: true);
                          if (ok) app.reviewExpense(e, 'Rejected');
                        },
                      ),
                      if (e.status == 'Approved')
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            label: 'Mark reimbursed',
                            icon: Icons.payments_outlined,
                            type: AppButtonType.text,
                            compact: true,
                            onPressed: () {
                              app.reviewExpense(e, 'Reimbursed');
                              showAppSnack(context, 'Marked as reimbursed.');
                            },
                          ),
                        ),
                    ],
                  ),
              ]),
          ],
        );
      },
    );
  }
}
