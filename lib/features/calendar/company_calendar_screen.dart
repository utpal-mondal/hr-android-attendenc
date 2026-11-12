import 'package:office_management/core/common.dart';

class CompanyCalendarScreen extends StatefulWidget {
  const CompanyCalendarScreen({super.key});

  @override
  State<CompanyCalendarScreen> createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selected = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Company Calendar',
      subtitle: 'Holidays, meetings, leave and events',
      builder: (context) {
        final app = context.watch<AppController>();
        final entries = app.calendarEntries();
        List<CalendarEntry> on(DateTime d) => entries.where((e) => sameDay(e.date, d)).toList();
        final dayEntries = on(_selected);
        final upcoming = app.holidays.where((h) => !h.date.isBefore(dateOnly(DateTime.now()))).take(5).toList();

        final cal = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: MonthCalendar(
                month: _month,
                selected: _selected,
                onMonthChanged: (m) => setState(() => _month = m),
                onSelect: (d) => setState(() => _selected = d),
                markersFor: (d) => on(d).map((e) => e.color).toSet().toList(),
                fillFor: (d) => d.weekday >= 6 ? AppColors.textSecondary : null,
              ),
            ),
            const Gap(12),
            Wrap(spacing: 14, runSpacing: 6, children: const [
              _Legend('Holiday', AppColors.teal),
              _Legend('Meeting', AppColors.info),
              _Legend('Leave', AppColors.purple),
              _Legend('WFH', AppColors.warning),
              _Legend('Event', Color(0xFFC11574)),
            ]),
          ],
        );

        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: Fmt.fullDate(_selected)),
            if (dayEntries.isEmpty)
              AppCard(child: Text(_selected.weekday >= 6 ? 'Weekend' : 'Nothing scheduled for this day.', style: const TextStyle(color: AppColors.textSecondary)))
            else
              for (final e in dayEntries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 5, height: 40, decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (e.subtitle.isNotEmpty) Text(e.subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                        ]),
                      ),
                      StatusBadge(label: e.type, color: e.color),
                    ]),
                  ),
                ),
            const Gap(14),
            const SectionHeader(title: 'Upcoming holidays'),
            for (final h in upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.celebration_outlined, color: AppColors.teal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${Fmt.weekday(h.date)}, ${Fmt.dateShort(h.date)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ]),
                ),
              ),
          ],
        );
        return TwoColumn(left: cal, right: side, leftFlex: 3, rightFlex: 2);
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      ]);
}
