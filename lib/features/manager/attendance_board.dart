import 'package:office_management/core/common.dart';
import 'package:office_management/features/attendance/punch_location_view.dart';

/// Daily attendance board for a set of employees (a manager's team, or the
/// whole company for HR / admin). Shared by every role so they all see the
/// same layout: day picker, summary, filter tiles, sortable list and export.
class AttendanceBoard extends StatefulWidget {
  const AttendanceBoard({super.key, this.ids, this.showDepartmentFilter = false, this.profileBase = '/manager/team'});
  final Set<String>? ids; // null = everyone
  final bool showDepartmentFilter;
  final String profileBase;

  @override
  State<AttendanceBoard> createState() => _AttendanceBoardState();
}

/// What a row means on the selected day. Unlike [AttendanceStatus], "no
/// record yet" today is "Not checked in", not "Absent".
enum _Bucket { checkedIn, late, wfh, leave, notIn }

enum _Sort { name, checkIn, status }

class _Row {
  _Row(this.employee, this.record, this.status, this.lateBy, this.shift);
  final Employee employee;
  final Attendance? record;
  final AttendanceStatus status;
  final Duration? lateBy;
  final Shift shift;

  bool get hasPunch => record?.checkIn != null;
}

class _AttendanceBoardState extends State<AttendanceBoard> {
  DateTime _day = dateOnly(DateTime.now());
  _Bucket? _bucket;
  String _dept = 'All';
  String _query = '';
  _Sort _sort = _Sort.name;

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(now.year - 1), lastDate: dateOnly(now));
    if (d != null) setState(() => _day = d);
  }

  void _shiftDay(int days) => setState(() => _day = DateTime(_day.year, _day.month, _day.day + days));

  static bool _inBucket(_Row r, _Bucket b) => switch (b) {
        _Bucket.checkedIn => r.hasPunch,
        _Bucket.late => r.status == AttendanceStatus.late,
        _Bucket.wfh => r.status == AttendanceStatus.wfh,
        _Bucket.leave => r.status == AttendanceStatus.leave,
        _Bucket.notIn => !r.hasPunch && r.status != AttendanceStatus.leave && r.status != AttendanceStatus.holiday,
      };

  static Duration? _lateBy(Attendance? a, Shift s) {
    final inAt = a?.checkIn;
    if (inAt == null || a!.status != AttendanceStatus.late) return null;
    final due = DateTime(inAt.year, inAt.month, inAt.day, s.startHour, s.startMinute);
    final d = inAt.difference(due);
    return d.isNegative ? null : d;
  }

  static Duration _shiftLength(Shift s) {
    var m = (s.endHour * 60 + s.endMinute) - (s.startHour * 60 + s.startMinute);
    if (m <= 0) m += 24 * 60;
    return Duration(minutes: m);
  }

  void _export(List<_Row> rows) {
    String cell(String v) => v.contains(RegExp(r'[",\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
    final b = StringBuffer('Employee,Department,Designation,Shift,Check-in,Check-out,Worked,Status,Check-in location,Check-out location\n');
    for (final r in rows) {
      final a = r.record;
      String loc(PunchLocation? l) => l == null || !l.isReal ? '' : '${l.latitude.toStringAsFixed(5)} ${l.longitude.toStringAsFixed(5)}';
      b.writeln([
        r.employee.name,
        r.employee.department,
        r.employee.designation,
        r.shift.name,
        a?.checkIn == null ? '' : Fmt.time(a!.checkIn),
        a?.checkOut == null ? '' : Fmt.time(a!.checkOut),
        r.hasPunch ? Fmt.duration(a!.worked) : '',
        _statusLabel(r),
        loc(a?.checkInLocation),
        loc(a?.checkOutLocation),
      ].map(cell).join(','));
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    showAppSnack(context, '${rows.length} rows for ${Fmt.date(_day)} copied as CSV. Paste into Excel or Google Sheets.');
  }

  String _statusLabel(_Row r) => !r.hasPunch && r.status == AttendanceStatus.absent && sameDay(_day, DateTime.now()) ? 'Not checked in' : r.status.label;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final isToday = sameDay(_day, DateTime.now());
    final isWeekend = _day.weekday >= 6;
    final holiday = app.holidays.where((h) => sameDay(h.date, _day)).firstOrNull;
    final isWfhDay = _day.weekday == AppController.wfhWeekday;

    // Everyone in scope for the day, before search / filters.
    final all = <_Row>[
      for (final e in app.employees.where((e) => e.active && (widget.ids == null || widget.ids!.contains(e.id))))
        () {
          final rec = app.recordOn(e.id, _day);
          final shift = app.shiftOf(e);
          return _Row(e, rec, rec?.status ?? AttendanceStatus.absent, _lateBy(rec, shift), shift);
        }(),
    ];
    final inDept = all.where((r) => _dept == 'All' || r.employee.department == _dept).toList();
    final counts = {for (final b in _Bucket.values) b: inDept.where((r) => _inBucket(r, b)).length};

    final q = _query.trim().toLowerCase();
    final rows = inDept.where((r) {
      if (_bucket != null && !_inBucket(r, _bucket!)) return false;
      if (q.isEmpty) return true;
      return r.employee.name.toLowerCase().contains(q) || r.employee.designation.toLowerCase().contains(q) || r.employee.department.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => switch (_sort) {
            _Sort.name => a.employee.name.compareTo(b.employee.name),
            _Sort.checkIn => (a.record?.checkIn ?? DateTime(9999)).compareTo(b.record?.checkIn ?? DateTime(9999)),
            _Sort.status => a.status.index != b.status.index ? a.status.index.compareTo(b.status.index) : a.employee.name.compareTo(b.employee.name),
          });

    final wide = Responsive.width(context) >= 900;
    final offDay = isWeekend || holiday != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayBar(
          day: _day,
          isToday: isToday,
          onPrev: () => _shiftDay(-1),
          onNext: isToday ? null : () => _shiftDay(1),
          onPick: _pick,
          onToday: isToday ? null : () => setState(() => _day = dateOnly(DateTime.now())),
        ),
        if (holiday != null || isWeekend || isWfhDay) ...[
          const Gap(10),
          _Banner(
            icon: holiday != null ? Icons.celebration_outlined : (isWeekend ? Icons.weekend_outlined : Icons.home_work_outlined),
            color: holiday != null || isWeekend ? AppColors.teal : AppColors.info,
            text: holiday != null
                ? '${holiday.name} - public holiday. Attendance is not expected.'
                : isWeekend
                    ? 'Weekend - attendance is not expected. Anyone who worked is still listed.'
                    : 'Wednesday is an office-wide work-from-home day. Check-in and check-out work from any location.',
          ),
        ],
        const Gap(14),
        _Summary(total: inDept.length, counts: counts, offDay: offDay, isToday: isToday),
        const Gap(12),
        _BucketTiles(
          counts: counts,
          selected: _bucket,
          isToday: isToday,
          onSelect: (b) => setState(() => _bucket = _bucket == b ? null : b),
        ),
        const Gap(16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: wide ? 320 : double.infinity, child: SearchField(hint: 'Search name, role or department', onChanged: (v) => setState(() => _query = v))),
            if (widget.showDepartmentFilter)
              _MenuChip<String>(
                icon: Icons.apartment_outlined,
                label: _dept == 'All' ? 'All departments' : _dept,
                values: ['All', ...app.departments.map((d) => d.name).where((n) => n.isNotEmpty).toSet()],
                labelOf: (v) => v == 'All' ? 'All departments' : v,
                onSelected: (v) => setState(() => _dept = v),
              ),
            _MenuChip<_Sort>(
              icon: Icons.sort,
              label: switch (_sort) { _Sort.name => 'Sort: Name', _Sort.checkIn => 'Sort: Check-in time', _Sort.status => 'Sort: Status' },
              values: _Sort.values,
              labelOf: (s) => switch (s) { _Sort.name => 'Name (A-Z)', _Sort.checkIn => 'Check-in time (earliest first)', _Sort.status => 'Status' },
              onSelected: (s) => setState(() => _sort = s),
            ),
            AppButton(
              label: 'Export CSV',
              icon: Icons.file_download_outlined,
              type: AppButtonType.secondary,
              compact: true,
              onPressed: rows.isEmpty ? null : () => _export(rows),
            ),
          ],
        ),
        const Gap(8),
        Text(
          'Showing ${rows.length} of ${inDept.length} employees${_bucket != null ? ' · filtered by ${_bucketLabel(_bucket!, isToday)}' : ''}',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const Gap(10),
        if (rows.isEmpty)
          AppCard(
            child: EmptyState(
              title: all.isEmpty ? 'No employees to show' : 'No matching employees',
              message: all.isEmpty ? 'Nobody is assigned to this view yet.' : 'Try another filter or search term.',
              icon: Icons.search_off,
            ),
          )
        else
          // Table only when the content area (not the window) fits every
          // column; otherwise readable cards instead of sideways scrolling.
          LayoutBuilder(builder: (context, c) => c.maxWidth >= 1000 ? _table(rows, isToday) : _cards(rows, isToday)),
      ],
    );
  }

  Widget _table(List<_Row> rows, bool isToday) => ScrollableTable(
            columnSpacing: 18,
            columns: const ['Employee', 'Shift', 'Check-in', 'Check-out', 'Worked', 'Location', 'Status'],
            rows: [
              for (final r in rows)
                [
                  _EmployeeCell(row: r, onTap: () => context.push('${widget.profileBase}/${r.employee.id}')),
                  _TwoLine(r.shift.name, '${Fmt.hm(r.shift.startHour, r.shift.startMinute)} - ${Fmt.hm(r.shift.endHour, r.shift.endMinute)}'),
                  _CheckInCell(row: r),
                  _CheckOutCell(row: r, isToday: isToday),
                  _WorkedCell(row: r, target: _shiftLength(r.shift), width: 92),
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 170), child: AttendancePlaceLink(record: r.record, employeeName: r.employee.name)),
                  _StatusPill(label: _statusLabel(r), color: _statusColor(r)),
                ],
            ],
          );

  /// Two cards per row on mid-size screens, one on phones.
  Widget _cards(List<_Row> rows, bool isToday) => ResponsiveGrid(minTileWidth: 340, spacing: 10, children: [
        for (final r in rows)
          _MobileRow(
            row: r,
            isToday: isToday,
            statusLabel: _statusLabel(r),
            statusColor: _statusColor(r),
            target: _shiftLength(r.shift),
            onTap: () => context.push('${widget.profileBase}/${r.employee.id}'),
          ),
      ]);

  Color _statusColor(_Row r) => !r.hasPunch && r.status == AttendanceStatus.absent && sameDay(_day, DateTime.now()) ? AppColors.textSecondary : r.status.color;
}

String _bucketLabel(_Bucket b, bool isToday) => switch (b) {
      _Bucket.checkedIn => 'Checked in',
      _Bucket.late => 'Late',
      _Bucket.wfh => 'WFH',
      _Bucket.leave => 'On leave',
      _Bucket.notIn => isToday ? 'Not checked in' : 'Absent',
    };

// ───────────────────────────────────────────────────────────── header parts

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day, required this.isToday, required this.onPrev, required this.onNext, required this.onPick, required this.onToday});
  final DateTime day;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(children: [
        IconButton(tooltip: 'Previous day', icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(Responsive.width(context) < 520 ? '${Fmt.weekday(day)}, ${Fmt.date(day)}' : Fmt.fullDate(day), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'Today', color: AppColors.teal),
                ],
              ]),
            ),
          ),
        ),
        if (onToday != null) TextButton(onPressed: onToday, child: const Text('Today')),
        IconButton(tooltip: 'Next day', icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

/// Attendance rate plus a stacked bar of how the day splits.
class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.counts, required this.offDay, required this.isToday});
  final int total;
  final Map<_Bucket, int> counts;
  final bool offDay;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final inCount = counts[_Bucket.checkedIn] ?? 0;
    final leave = counts[_Bucket.leave] ?? 0;
    final notIn = counts[_Bucket.notIn] ?? 0;
    final wfh = counts[_Bucket.wfh] ?? 0;
    final late = counts[_Bucket.late] ?? 0;
    final onTimeOffice = (inCount - wfh - late).clamp(0, total);
    final expected = total - leave;
    final rate = expected <= 0 ? 0 : (inCount / expected * 100).round();

    final segments = <(String, int, Color)>[
      ('On time', onTimeOffice, AppColors.success),
      ('Late', late, AppColors.warning),
      ('WFH', wfh, AppColors.info),
      ('On leave', leave, AppColors.purple),
      (isToday ? 'Not checked in' : 'Absent', notIn, isToday ? const Color(0xFFD0D5DD) : AppColors.danger),
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(offDay && inCount == 0 ? '--' : '$rate%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                offDay ? 'Non-working day · $inCount checked in' : 'Attendance · $inCount of $expected expected employees checked in',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: total == 0
                ? Container(color: AppColors.border)
                : Row(children: [
                    for (final s in segments)
                      if (s.$2 > 0) Expanded(flex: s.$2, child: Container(color: s.$3)),
                  ]),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          for (final s in segments)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text('${s.$1} ${s.$2}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ]),
        ]),
      ]),
    );
  }
}

/// Clickable count tiles that double as filters.
class _BucketTiles extends StatelessWidget {
  const _BucketTiles({required this.counts, required this.selected, required this.isToday, required this.onSelect});
  final Map<_Bucket, int> counts;
  final _Bucket? selected;
  final bool isToday;
  final ValueChanged<_Bucket> onSelect;

  @override
  Widget build(BuildContext context) {
    final tiles = <(_Bucket, IconData, Color)>[
      (_Bucket.checkedIn, Icons.login_rounded, AppColors.success),
      (_Bucket.late, Icons.watch_later_outlined, AppColors.warning),
      (_Bucket.wfh, Icons.home_work_outlined, AppColors.info),
      (_Bucket.leave, Icons.beach_access_outlined, AppColors.purple),
      (_Bucket.notIn, isToday ? Icons.hourglass_empty_rounded : Icons.cancel_outlined, isToday ? AppColors.textSecondary : AppColors.danger),
    ];
    final widgets = [
      for (final t in tiles)
        _Tile(
          label: t.$1 == _Bucket.notIn && isToday && Responsive.width(context) < 640 ? 'Not in yet' : _bucketLabel(t.$1, isToday),
          value: counts[t.$1] ?? 0,
          icon: t.$2,
          color: t.$3,
          selected: selected == t.$1,
          onTap: () => onSelect(t.$1),
        ),
    ];
    // Evenly sized columns: all five in one row when labels fit, else 3 + 2.
    return LayoutBuilder(builder: (context, c) {
      const gap = 10.0;
      final cols = c.maxWidth >= 640 ? widgets.length : (c.maxWidth >= 330 ? 3 : 2);
      final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final w in widgets) SizedBox(width: tileW, child: w)]);
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.icon, required this.color, required this.selected, required this.onTap});
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: selected ? color : AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
              if (selected) Icon(Icons.filter_alt, size: 14, color: color),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({required this.icon, required this.label, required this.values, required this.labelOf, required this.onSelected});
  final IconData icon;
  final String label;
  final Iterable<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (_) => [for (final v in values) PopupMenuItem<T>(value: v, child: Text(labelOf(v)))],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── row parts

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => StatusBadge(label: label, color: color);
}

class _TwoLine extends StatelessWidget {
  const _TwoLine(this.top, this.bottom, {this.bottomColor = AppColors.textSecondary});
  final String top;
  final String bottom;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(top, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (bottom.isNotEmpty)
            Text(bottom, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: bottomColor, fontWeight: FontWeight.w500)),
        ],
      );
}

class _EmployeeCell extends StatelessWidget {
  const _EmployeeCell({required this.row, required this.onTap});
  final _Row row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = row.employee;
    final sub = [e.designation, e.department].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AvatarWidget(name: e.name, size: 34),
          const SizedBox(width: 10),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 175), child: _TwoLine(e.name, sub)),
        ]),
      ),
    );
  }
}

String _lateText(Duration d) => d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m late' : '${d.inMinutes}m late';

class _CheckInCell extends StatelessWidget {
  const _CheckInCell({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final a = row.record;
    if (a?.checkIn == null) return const Text('--', style: TextStyle(color: AppColors.textSecondary));
    final late = row.lateBy;
    return _TwoLine(
      Fmt.time(a!.checkIn),
      late != null ? _lateText(late) : (a.isWfh ? 'Remote' : 'On time'),
      bottomColor: late != null ? AppColors.warning : (a.isWfh ? AppColors.info : AppColors.success),
    );
  }
}

class _CheckOutCell extends StatelessWidget {
  const _CheckOutCell({required this.row, required this.isToday});
  final _Row row;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final a = row.record;
    if (a?.checkIn == null) return const Text('--', style: TextStyle(color: AppColors.textSecondary));
    if (a!.checkOut != null) return Text(Fmt.time(a.checkOut), style: const TextStyle(fontWeight: FontWeight.w600));
    return isToday
        ? const StatusBadge(label: 'Working', color: AppColors.success, icon: Icons.circle)
        : const StatusBadge(label: 'No check-out', color: AppColors.warning);
  }
}

/// Worked time with a thin bar against the shift length.
class _WorkedCell extends StatelessWidget {
  const _WorkedCell({required this.row, required this.target, this.width});
  final _Row row;
  final Duration target;

  /// Fixed width inside the table (cells there are unbounded); null fills the parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final a = row.record;
    if (a?.checkIn == null) return const Text('--', style: TextStyle(color: AppColors.textSecondary));
    final worked = a!.worked;
    final pct = target.inMinutes == 0 ? 0.0 : (worked.inMinutes / target.inMinutes).clamp(0.0, 1.0);
    final color = pct >= 1 ? AppColors.success : AppColors.teal;
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Fmt.duration(worked), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: AppColors.border, color: color),
        ),
      ]),
    );
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.row, required this.isToday, required this.statusLabel, required this.statusColor, required this.target, required this.onTap});
  final _Row row;
  final bool isToday;
  final String statusLabel;
  final Color statusColor;
  final Duration target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = row.employee;
    final sub = [e.designation, e.department].where((s) => s.isNotEmpty).join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AvatarWidget(name: e.name, size: 38),
          const SizedBox(width: 12),
          Expanded(child: _TwoLine(e.name, sub)),
          const SizedBox(width: 8),
          _StatusPill(label: statusLabel, color: statusColor),
        ]),
        if (row.hasPunch) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _labelled('Check-in', _CheckInCell(row: row))),
            Expanded(child: _labelled('Check-out', _CheckOutCell(row: row, isToday: isToday))),
            Expanded(child: _labelled('Worked', _WorkedCell(row: row, target: target))),
          ]),
          const SizedBox(height: 8),
          AttendancePlaceLink(record: row.record, employeeName: e.name),
        ] else ...[
          const SizedBox(height: 8),
          Text('Shift ${row.shift.name} · ${Fmt.hm(row.shift.startHour, row.shift.startMinute)} - ${Fmt.hm(row.shift.endHour, row.shift.endMinute)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }

  Widget _labelled(String label, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        child,
      ]);
}
