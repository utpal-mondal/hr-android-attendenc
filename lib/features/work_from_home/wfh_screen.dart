import 'package:office_management/core/common.dart';

class WfhScreen extends StatefulWidget {
  const WfhScreen({super.key});

  @override
  State<WfhScreen> createState() => _WfhScreenState();
}

class _WfhScreenState extends State<WfhScreen> {
  RequestStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Work From Home',
      subtitle: 'Remote work requests',
      actions: [
        AppButton(label: 'Request', icon: Icons.add, compact: true, onPressed: () => context.push('/employee/wfh/apply')),
        const SizedBox(width: 8),
      ],
      builder: (context) {
        final app = context.watch<AppController>();
        final used = app.wfhUsedThisMonth(app.me.id);
        const quota = AppController.wfhMonthlyQuota;
        final list = app.wfhFor(app.me.id).where((w) => _filter == null || w.status == _filter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.home_work_outlined, color: AppColors.info),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Monthly WFH quota - ${Fmt.monthYear(DateTime.now())}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                  const Gap(14),
                  LabeledProgress(value: used / quota, color: AppColors.info, height: 10),
                  const Gap(8),
                  Text('${used.toInt()} of ${quota.toInt()} days used  -  ${(quota - used).clamp(0, quota).toInt()} remaining', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Gap(20),
            const SectionHeader(title: 'Request history'),
            AppFilterChips<RequestStatus?>(
              options: const [null, RequestStatus.pending, RequestStatus.approved, RequestStatus.rejected],
              selected: _filter,
              labelOf: (s) => s == null ? 'All' : s.label,
              onSelected: (s) => setState(() => _filter = s),
            ),
            const Gap(14),
            if (list.isEmpty)
              AppCard(child: EmptyState(title: 'No WFH requests', message: 'Request remote work when you need it.', icon: Icons.home_work_outlined, actionLabel: 'Request WFH', onAction: () => context.push('/employee/wfh/apply')))
            else
              ResponsiveGrid(minTileWidth: 400, children: [
                for (final w in list)
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(sameDay(w.from, w.to) ? Fmt.date(w.from) : '${Fmt.dateShort(w.from)} - ${Fmt.date(w.to)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          requestBadge(w.status),
                        ]),
                        const Gap(6),
                        Text('${w.days} day(s)', style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 13)),
                        const Gap(6),
                        Text(w.reason),
                        const Gap(6),
                        IconText(Icons.schedule, 'Applied ${Fmt.dateShort(w.appliedOn)}'),
                      ],
                    ),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
