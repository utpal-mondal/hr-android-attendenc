import 'package:office_management/core/common.dart';

class PayslipsScreen extends StatelessWidget {
  const PayslipsScreen({super.key});

  void _detail(BuildContext context, Payslip p) {
    Widget row(String k, double v, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
            Text(Fmt.money(v), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
          ]),
        );
    showAppSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payslip - ${Fmt.monthYear(p.month)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('EARNINGS', style: TextStyle(fontSize: 11.5, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              row('Basic salary', p.basic),
              row('House rent allowance', p.hra),
              row('Special & other allowances', p.allowances),
              row('Gross earnings', p.gross, bold: true),
              const Divider(height: 24),
              const Text('DEDUCTIONS', style: TextStyle(fontSize: 11.5, letterSpacing: 1, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              row('Provident fund', p.pf),
              row('Professional tax', p.professionalTax),
              row('Income tax (TDS)', p.incomeTax),
              row('Total deductions', p.deductions, bold: true, color: AppColors.danger),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha:0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Expanded(child: Text('Net pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Text(Fmt.money(p.net), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.success)),
                ]),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Download PDF',
                icon: Icons.file_download_outlined,
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Downloading payslip for ${Fmt.monthYear(p.month)} (demo)...');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Payslips',
      subtitle: 'Monthly salary statements',
      shimmer: ShimmerLayout.list,
      maxWidth: 800,
      builder: (context) {
        final app = context.watch<AppController>();
        final list = app.payslips;
        if (list.isEmpty) return const EmptyState(title: 'No payslips yet', icon: Icons.payments_outlined);
        final latest = list.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [AppColors.teal, Color(0xFF16453F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest - ${Fmt.monthYear(latest.month)}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(Fmt.money(latest.net), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                  const Text('Net pay', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _detail(context, latest),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('View breakdown'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.teal),
                  ),
                ],
              ),
            ),
            const Gap(20),
            const SectionHeader(title: 'All payslips'),
            for (final p in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => _detail(context, p),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.payments_outlined, color: AppColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(Fmt.monthYear(p.month), style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Gross ${Fmt.money(p.gross)}  -  Deductions ${Fmt.money(p.deductions)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                    Text(Fmt.money(p.net), style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () => showAppSnack(context, 'Downloading payslip (demo)...')),
                  ]),
                ),
              ),
          ],
        );
      },
    );
  }
}
