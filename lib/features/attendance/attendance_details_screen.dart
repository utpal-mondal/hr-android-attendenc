import 'package:office_management/core/common.dart';

class AttendanceDetailsScreen extends StatelessWidget {
  const AttendanceDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Attendance Details',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        final a = app.attendanceById(id);
        if (a == null) {
          return const EmptyState(title: 'Record not found', message: 'This attendance record is no longer available.', icon: Icons.search_off);
        }
        final s = a.status;
        final branch = app.branches.where((b) => b.name == a.office).toList();

        final summary = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(Fmt.fullDate(a.date), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                attendanceBadge(s),
              ]),
              const Gap(16),
              Wrap(spacing: 28, runSpacing: 14, children: [
                _kv('Check-in', Fmt.time(a.checkIn)),
                _kv('Check-out', a.checkOut == null && a.checkIn != null ? 'Working' : Fmt.time(a.checkOut)),
                _kv('Break time', Fmt.duration(a.breakTime)),
                _kv('Total hours', Fmt.duration(a.worked)),
                _kv('Overtime', Fmt.duration(a.overtime)),
              ]),
              if (a.note != null) ...[
                const Gap(14),
                IconText(Icons.sticky_note_2_outlined, a.note!),
              ],
            ],
          ),
        );

        final office = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Office information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Gap(12),
              _kv('Location', a.office),
              if (branch.isNotEmpty) ...[
                const Gap(10),
                _kv('Address', branch.first.address),
                const Gap(10),
                _kv('Working hours', branch.first.workingHours),
              ],
              const Gap(10),
              _kv('Verification', a.office.startsWith('Remote') ? 'Work from home' : 'Geofence verified (simulated)'),
            ],
          ),
        );

        final timeline = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Gap(12),
              if (a.events.isEmpty)
                const Text('No check-in activity recorded for this day.', style: TextStyle(color: AppColors.textSecondary))
              else
                for (final e in a.events)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      const Icon(Icons.circle, size: 9, color: AppColors.teal),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.label)),
                      Text(Fmt.time(e.time), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
            ],
          ),
        );

        final canRegularize = a.status != AttendanceStatus.holiday && !sameDay(a.date, DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            summary,
            const Gap(16),
            TwoColumn(left: timeline, right: office, leftFlex: 1, rightFlex: 1),
            if (canRegularize) ...[
              const Gap(20),
              AppButton(
                label: 'Request regularization',
                icon: Icons.edit_calendar_outlined,
                type: AppButtonType.secondary,
                onPressed: () {
                  final d = a.date;
                  final ds = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  context.push('/employee/attendance/regularization?date=$ds');
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        ],
      );
}
