import 'enums.dart';

class AttendanceBreak {
  AttendanceBreak({required this.start, this.end});
  final DateTime start;
  DateTime? end;

  Duration get duration {
    final d = (end ?? DateTime.now()).difference(start);
    return d.isNegative ? Duration.zero : d;
  }
}

class AttendanceEvent {
  AttendanceEvent(this.type, this.time);
  final AttendanceEventType type;
  final DateTime time;

  String get label => switch (type) {
        AttendanceEventType.checkIn => 'Checked in',
        AttendanceEventType.breakStart => 'Break started',
        AttendanceEventType.breakEnd => 'Break ended',
        AttendanceEventType.checkOut => 'Checked out',
      };
}

class Attendance {
  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    List<AttendanceBreak>? breaks,
    this.office = 'Kolkata HQ',
    this.note,
  }) : breaks = breaks ?? [];

  final String id;
  final String employeeId;
  final DateTime date;
  AttendanceStatus status;
  DateTime? checkIn;
  DateTime? checkOut;
  final List<AttendanceBreak> breaks;
  String office;
  String? note;

  Duration get breakTime => breaks.fold(Duration.zero, (sum, b) => sum + b.duration);

  Duration get worked {
    final start = checkIn;
    if (start == null) return Duration.zero;
    final end = checkOut ?? DateTime.now();
    final d = end.difference(start) - breakTime;
    return d.isNegative ? Duration.zero : d;
  }

  Duration get overtime {
    const regular = Duration(hours: 8);
    return worked > regular ? worked - regular : Duration.zero;
  }

  bool get hasWorkData => checkIn != null;

  List<AttendanceEvent> get events {
    final list = <AttendanceEvent>[];
    if (checkIn != null) list.add(AttendanceEvent(AttendanceEventType.checkIn, checkIn!));
    for (final b in breaks) {
      list.add(AttendanceEvent(AttendanceEventType.breakStart, b.start));
      if (b.end != null) list.add(AttendanceEvent(AttendanceEventType.breakEnd, b.end!));
    }
    if (checkOut != null) list.add(AttendanceEvent(AttendanceEventType.checkOut, checkOut!));
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }
}

/// Aggregated numbers used by dashboards and reports.
class AttendanceSummary {
  AttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.wfh = 0,
    this.leave = 0,
    this.halfDay = 0,
    this.absent = 0,
    this.holiday = 0,
    this.avgHours = 0,
    this.overtimeHours = 0,
  });
  int present, late, wfh, leave, halfDay, absent, holiday;
  double avgHours;
  double overtimeHours;

  int get workingDays => present + late + wfh + leave + halfDay + absent;
  int get attended => present + late + wfh + halfDay;
  double get attendancePct => workingDays == 0 ? 0 : attended / workingDays * 100;

  static AttendanceSummary of(Iterable<Attendance> records) {
    final s = AttendanceSummary();
    var minutes = 0;
    var counted = 0;
    var ot = 0;
    for (final a in records) {
      switch (a.status) {
        case AttendanceStatus.present:
          s.present++;
        case AttendanceStatus.late:
          s.late++;
        case AttendanceStatus.wfh:
          s.wfh++;
        case AttendanceStatus.leave:
          s.leave++;
        case AttendanceStatus.halfDay:
          s.halfDay++;
        case AttendanceStatus.absent:
          s.absent++;
        case AttendanceStatus.holiday:
          s.holiday++;
      }
      if (a.checkIn != null && a.checkOut != null) {
        minutes += a.worked.inMinutes;
        ot += a.overtime.inMinutes;
        counted++;
      }
    }
    s.avgHours = counted == 0 ? 0 : minutes / counted / 60;
    s.overtimeHours = ot / 60;
    return s;
  }
}
