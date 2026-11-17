import 'dart:async';

import 'package:office_management/core/common.dart';

import '../repositories/app_repository.dart';
import '../repositories/mock_app_repository.dart';

/// Holds all demo data and business rules.
///
/// Flow: UI -> AppController -> AppRepository (mock now, REST API later).
class AppController extends ChangeNotifier {
  AppController(this._repo);

  final AppRepository _repo;

  /// User-facing messages for writes the backend rejected. The app root shows
  /// each one as an error snackbar; the local change has already been undone.
  Stream<String> get writeErrors => _writeErrors.stream;
  final _writeErrors = StreamController<String>.broadcast();

  @override
  void dispose() {
    _writeErrors.close();
    super.dispose();
  }

  /// Runs a repository write. On failure runs [undo] (to roll back the
  /// optimistic local change), reports the error and returns false.
  Future<bool> _persist(Future<void> Function() write, {void Function()? undo}) async {
    try {
      await write();
      return true;
    } catch (e) {
      undo?.call();
      final msg = e is RepoWriteException ? e.message : 'Something went wrong while saving. Please try again.';
      if (!_writeErrors.isClosed) _writeErrors.add(msg);
      notifyListeners();
      return false;
    }
  }

  bool loading = false;
  bool loaded = false;
  String? error;

  UserRole? _role;
  String _meId = '';

  List<Employee> employees = [];
  List<Department> departments = [];
  List<Branch> branches = [];
  List<Shift> shifts = [];
  List<LeaveBalance> apiBalances = [];
  List<Holiday> holidays = [];
  List<Attendance> attendance = [];
  List<LeaveRequest> leaves = [];
  List<WFHRequest> wfhRequests = [];
  List<RegularizationRequest> regularizations = [];
  List<Announcement> announcements = [];
  List<AppNotification> notifications = [];
  List<DocumentItem> documents = [];
  List<Payslip> payslips = [];
  List<Expense> expenses = [];
  List<Meeting> meetings = [];
  List<Asset> assets = [];
  List<Ticket> tickets = [];
  List<AuditLog> auditLogs = [];

  int _seq = 500;
  String _newId(String prefix) => '$prefix${++_seq}';

  // ---------------------------------------------------------------- session

  UserRole? get role => _role;

  Future<void> start(UserRole role) {
    _role = role;
    _meId = _repo.userIdFor(role);
    return load(force: true);
  }

  void reset() {
    _role = null;
    _meId = '';
    loaded = false;
    loading = false;
    error = null;
    _loadedAt = null;
    _loading = null;
    _generation++; // results of a load still in flight are discarded
    notifyListeners();
  }

  /// While data is younger than this, `load()` is a no-op — screens and
  /// widget rebuilds can call it freely without hitting the network.
  /// Pass `force: true` to always refetch (sign-in, manual refresh).
  Duration dataFreshFor = const Duration(minutes: 2);

  DateTime? _loadedAt;
  Future<void>? _loading;

  /// Bumped on [reset] so a load started for a previous session never
  /// overwrites the data of the next one.
  int _generation = 0;

  Future<void> load({bool force = false}) {
    // Single-flight: concurrent callers share one in-flight load.
    final running = _loading;
    if (running != null) return running;
    if (!force &&
        loaded &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < dataFreshFor) {
      return Future.value();
    }
    final f = _load();
    _loading = f;
    return f.whenComplete(() {
      if (identical(_loading, f)) _loading = null;
    });
  }

  Future<void> _load() async {
    final gen = _generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final s = await _repo.load();
      if (gen != _generation) return; // signed out meanwhile
      employees = s.employees;
      departments = s.departments;
      branches = s.branches;
      shifts = s.shifts;
      holidays = s.holidays;
      attendance = s.attendance;
      leaves = s.leaves;
      wfhRequests = s.wfhRequests;
      regularizations = s.regularizations;
      announcements = s.announcements;
      notifications = s.notifications;
      documents = s.documents;
      payslips = s.payslips;
      expenses = s.expenses;
      meetings = s.meetings;
      assets = s.assets;
      tickets = s.tickets;
      auditLogs = s.auditLogs;
      apiBalances = s.leaveBalances;
      loaded = true;
      _loadedAt = DateTime.now();
    } catch (e) {
      if (gen != _generation) return;
      error = 'Could not load data. Please check your connection and try again.';
    }
    loading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- lookups

  Employee get me => employees.firstWhere(
        (e) => e.id == _meId,
        orElse: () => employees.isNotEmpty
            ? employees.first
            : Employee(
                id: 'me',
                name: 'User',
                email: '',
                phone: '',
                department: '',
                designation: '',
                branch: '',
                shift: '',
                joinDate: DateTime.now(),
              ),
      );

  Employee? employeeById(String id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  String nameOf(String id) => employeeById(id)?.name ?? 'Unknown';

  static final _fallbackShift =
      Shift(id: '0', name: 'General', startHour: 9, startMinute: 0, endHour: 18, endMinute: 0);

  Shift shiftOf(Employee e) =>
      shifts.firstWhere((s) => s.name == e.shift, orElse: () => shifts.isNotEmpty ? shifts.first : _fallbackShift);

  List<Employee> get team => employees.where((e) => e.managerId == _meId).toList();

  Set<String> get teamIds => team.map((e) => e.id).toSet();

  Set<String> get allIds => employees.map((e) => e.id).toSet();

  List<Employee> get managers {
    final list =
        employees.where((e) => e.role != UserRole.employee || employees.any((x) => x.managerId == e.id)).toList();
    return list.isEmpty ? employees : list;
  }

  int employeeCountIn(String department) => employees.where((e) => e.department == department).length;
  int employeeCountAt(String branch) => employees.where((e) => e.branch == branch).length;

  // ------------------------------------------------------------- attendance

  Attendance? _todayFor(String empId) {
    final t = dateOnly(DateTime.now());
    for (final a in attendance) {
      if (a.employeeId == empId && sameDay(a.date, t)) return a;
    }
    return null;
  }

  Attendance? get myToday => _todayFor(_meId);

  WorkState get workState {
    final a = myToday;
    if (a == null || a.checkIn == null) return WorkState.notStarted;
    if (a.checkOut != null) return WorkState.completed;
    if (a.breaks.isNotEmpty && a.breaks.last.end == null) return WorkState.onBreak;
    return WorkState.working;
  }

  List<Attendance> attendanceFor(String empId) {
    final list = attendance.where((a) => a.employeeId == empId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Attendance> get myAttendance => attendanceFor(_meId);

  Attendance? attendanceById(String id) {
    for (final a in attendance) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Attendance status of an employee on a given day (absent when no record).
  AttendanceStatus statusOn(String empId, DateTime d) {
    for (final a in attendance) {
      if (a.employeeId == empId && sameDay(a.date, d)) return a.status;
    }
    return AttendanceStatus.absent;
  }

  Attendance? recordOn(String empId, DateTime d) {
    for (final a in attendance) {
      if (a.employeeId == empId && sameDay(a.date, d)) return a;
    }
    return null;
  }

  List<Attendance> attendanceBetween(DateTime from, DateTime to, {Set<String>? ids}) {
    final a = dateOnly(from);
    final b = dateOnly(to);
    return attendance
        .where((r) => !r.date.isBefore(a) && !r.date.isAfter(b) && (ids == null || ids.contains(r.employeeId)))
        .toList();
  }

  bool _punching = false;

  /// Checks in for today. Returns false (and changes nothing) when the user
  /// is already checked in / done for the day, a punch is still in progress,
  /// or the server rejected it.
  Future<bool> checkIn({PunchLocation? location}) async {
    if (_punching || workState != WorkState.notStarted) return false;
    _punching = true;
    try {
      final now = DateTime.now();
      final e = me;
      final shift = shiftOf(e);
      final limit = DateTime(now.year, now.month, now.day, shift.startHour, shift.startMinute)
          .add(Duration(minutes: shift.graceMinutes));
      final rec = Attendance(
        id: 'A-${e.id}-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
        employeeId: e.id,
        date: dateOnly(now),
        status: now.isAfter(limit) ? AttendanceStatus.late : AttendanceStatus.present,
        checkIn: now,
        office: e.branch,
      )..punchLocation = location;
      final previous = attendance.where((a) => a.id == rec.id).toList();
      attendance.removeWhere((a) => a.id == rec.id);
      attendance.add(rec);
      notifyListeners();
      final ok = await _persist(() => _repo.saveAttendance(rec), undo: () {
        attendance.remove(rec);
        attendance.addAll(previous);
      });
      if (!ok) return false;
      _addNotification('Checked in', 'You checked in at ${Fmt.time(now)}.', 'attendance');
      notifyListeners();
      return true;
    } finally {
      _punching = false;
    }
  }

  Future<bool> startBreak() async {
    final a = myToday;
    if (_punching || a == null || workState != WorkState.working) return false;
    _punching = true;
    try {
      final b = AttendanceBreak(start: DateTime.now());
      a.breaks.add(b);
      notifyListeners();
      return await _persist(() => _repo.saveAttendance(a), undo: () => a.breaks.remove(b));
    } finally {
      _punching = false;
    }
  }

  Future<bool> endBreak() async {
    final a = myToday;
    if (_punching || a == null || workState != WorkState.onBreak) return false;
    _punching = true;
    try {
      final b = a.breaks.last;
      b.end = DateTime.now();
      notifyListeners();
      return await _persist(() => _repo.saveAttendance(a), undo: () => b.end = null);
    } finally {
      _punching = false;
    }
  }

  Future<bool> checkOut({PunchLocation? location}) async {
    final a = myToday;
    if (_punching || a == null || a.checkIn == null || a.checkOut != null) return false;
    _punching = true;
    try {
      final now = DateTime.now();
      final openBreak = a.breaks.isNotEmpty && a.breaks.last.end == null ? a.breaks.last : null;
      openBreak?.end = now;
      a.checkOut = now;
      a.punchLocation = location;
      notifyListeners();
      final ok = await _persist(() => _repo.saveAttendance(a), undo: () {
        a.checkOut = null;
        openBreak?.end = null;
      });
      if (!ok) return false;
      _addNotification('Checked out', 'Day completed - ${Fmt.duration(a.worked)} worked.', 'attendance');
      notifyListeners();
      return true;
    } finally {
      _punching = false;
    }
  }

  /// QR scan: toggles between check-in and check-out. Returns the message to
  /// show, or null when the punch failed (the error is already reported).
  Future<String?> qrScan({PunchLocation? location}) async {
    switch (workState) {
      case WorkState.notStarted:
        if (!await checkIn(location: location)) return null;
        return 'Checked in successfully at ${Fmt.time(myToday?.checkIn)}.';
      case WorkState.working:
      case WorkState.onBreak:
        if (!await checkOut(location: location)) return null;
        return 'Checked out successfully at ${Fmt.time(myToday?.checkOut)}.';
      case WorkState.completed:
        return 'Your attendance for today is already completed.';
    }
  }

  // ------------------------------------------------------------- leave / WFH

  static const Map<String, double> leaveQuota = {
    'Casual Leave': 12,
    'Sick Leave': 10,
    'Earned Leave': 18,
    'Comp Off': 4,
  };

  /// Leave types offered by the backend in API mode; demo quota in mock mode.
  List<String> get leaveTypes =>
      _repo.leaveTypeNames.isNotEmpty ? _repo.leaveTypeNames : leaveQuota.keys.toList();

  /// Expense / ticket categories for dropdowns (API lookups, demo in mock).
  List<String> get expenseCategories =>
      _repo.expenseCategoryNames.isNotEmpty ? _repo.expenseCategoryNames : const ['Travel', 'Meals', 'Equipment', 'Training', 'Software', 'Office'];

  List<String> get ticketCategories =>
      _repo.ticketCategoryNames.isNotEmpty ? _repo.ticketCategoryNames : const ['IT Support', 'HR Query', 'Facilities', 'Payroll', 'Other'];

  static const double wfhMonthlyQuota = 6;

  List<LeaveRequest> leavesFor(String empId) {
    final l = leaves.where((r) => r.employeeId == empId).toList();
    l.sort((a, b) => b.from.compareTo(a.from));
    return l;
  }

  List<LeaveBalance> balancesFor(String empId) {
    if (apiBalances.isNotEmpty && empId == _meId) return apiBalances;
    final mine = leaves.where((l) => l.employeeId == empId);
    return leaveQuota.entries.map((q) {
      double used = 0, pending = 0;
      for (final l in mine.where((l) => l.type == q.key)) {
        if (l.status == RequestStatus.approved) used += l.days;
        if (l.status == RequestStatus.pending) pending += l.days;
      }
      return LeaveBalance(type: q.key, total: q.value, used: used, pending: pending);
    }).toList();
  }

  List<WFHRequest> wfhFor(String empId) {
    final l = wfhRequests.where((r) => r.employeeId == empId).toList();
    l.sort((a, b) => b.from.compareTo(a.from));
    return l;
  }

  double wfhUsedThisMonth(String empId) {
    final now = DateTime.now();
    double used = 0;
    for (final w in wfhRequests.where((w) => w.employeeId == empId && w.status != RequestStatus.rejected)) {
      if (w.from.year == now.year && w.from.month == now.month) used += w.days;
    }
    return used;
  }

  static bool _overlaps(DateTime aFrom, DateTime aTo, DateTime bFrom, DateTime bTo) =>
      !dateOnly(aFrom).isAfter(dateOnly(bTo)) && !dateOnly(bFrom).isAfter(dateOnly(aTo));

  /// The user's pending/approved leave that overlaps [from]..[to], if any.
  LeaveRequest? overlappingLeave(DateTime from, DateTime to) {
    for (final l in leaves) {
      if (l.employeeId == _meId && l.status != RequestStatus.rejected && _overlaps(l.from, l.to, from, to)) return l;
    }
    return null;
  }

  /// The user's pending/approved WFH request that overlaps [from]..[to], if any.
  WFHRequest? overlappingWfh(DateTime from, DateTime to) {
    for (final w in wfhRequests) {
      if (w.employeeId == _meId && w.status != RequestStatus.rejected && _overlaps(w.from, w.to, from, to)) return w;
    }
    return null;
  }

  /// Submits a leave request. Returns false when it overlaps an existing
  /// request or the server rejected it (an error has been reported).
  Future<bool> submitLeave({
    required String type,
    required DateTime from,
    required DateTime to,
    required bool halfDay,
    required String reason,
    required bool attachment,
  }) async {
    if (overlappingLeave(from, to) != null) {
      _writeErrors.add('You already have a leave request for these dates.');
      return false;
    }
    final r = LeaveRequest(
      id: _newId('L'),
      employeeId: _meId,
      type: type,
      from: from,
      to: to,
      halfDay: halfDay,
      reason: reason,
      appliedOn: DateTime.now(),
      hasAttachment: attachment,
    );
    leaves.add(r);
    if (!await _persist(() => _repo.saveLeave(r), undo: () => leaves.remove(r))) return false;
    _addNotification('Leave request submitted', '$type for ${r.days % 1 == 0 ? r.days.toInt() : r.days} day(s) is pending approval.', 'leave');
    notifyListeners();
    return true;
  }

  Future<bool> submitWfh({required DateTime from, required DateTime to, required String reason}) async {
    if (overlappingWfh(from, to) != null) {
      _writeErrors.add('You already have a work from home request for these dates.');
      return false;
    }
    final r = WFHRequest(id: _newId('W'), employeeId: _meId, from: from, to: to, reason: reason, appliedOn: DateTime.now());
    wfhRequests.add(r);
    if (!await _persist(() => _repo.saveWfh(r), undo: () => wfhRequests.remove(r))) return false;
    _addNotification('WFH request submitted', 'Your work from home request is pending approval.', 'leave');
    notifyListeners();
    return true;
  }

  Future<bool> submitRegularization({
    required DateTime date,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
    required bool attachment,
  }) async {
    final r = RegularizationRequest(
      id: _newId('R'),
      employeeId: _meId,
      date: date,
      requestedIn: checkIn,
      requestedOut: checkOut,
      reason: reason,
      appliedOn: DateTime.now(),
      hasAttachment: attachment,
    );
    regularizations.add(r);
    if (!await _persist(() => _repo.saveRegularization(r), undo: () => regularizations.remove(r))) return false;
    _addNotification('Regularization submitted', 'Your attendance correction is with your manager.', 'attendance');
    notifyListeners();
    return true;
  }

  List<RegularizationRequest> regularizationsFor(String empId) {
    final l = regularizations.where((r) => r.employeeId == empId).toList();
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  // --------------------------------------------------------------- approvals

  String _rangeText(DateTime a, DateTime b) => sameDay(a, b) ? Fmt.date(a) : '${Fmt.dateShort(a)} - ${Fmt.date(b)}';

  List<ApprovalItem> approvals({Set<String>? employeeIds, Set<ApprovalKind>? kinds}) {
    bool ok(String id) => employeeIds == null || employeeIds.contains(id);
    bool kindOk(ApprovalKind k) => kinds == null || kinds.contains(k);
    final items = <ApprovalItem>[];
    if (kindOk(ApprovalKind.leave)) {
      for (final l in leaves.where((l) => ok(l.employeeId))) {
        items.add(ApprovalItem(
          id: l.id,
          kind: ApprovalKind.leave,
          employeeId: l.employeeId,
          title: l.type,
          detail: '${_rangeText(l.from, l.to)}  -  ${l.days % 1 == 0 ? l.days.toInt() : l.days} day(s)',
          reason: l.reason,
          status: l.status,
          appliedOn: l.appliedOn,
        ));
      }
    }
    if (kindOk(ApprovalKind.wfh)) {
      for (final w in wfhRequests.where((w) => ok(w.employeeId))) {
        items.add(ApprovalItem(
          id: w.id,
          kind: ApprovalKind.wfh,
          employeeId: w.employeeId,
          title: 'Work from home',
          detail: '${_rangeText(w.from, w.to)}  -  ${w.days} day(s)',
          reason: w.reason,
          status: w.status,
          appliedOn: w.appliedOn,
        ));
      }
    }
    if (kindOk(ApprovalKind.regularization)) {
      for (final r in regularizations.where((r) => ok(r.employeeId))) {
        items.add(ApprovalItem(
          id: r.id,
          kind: ApprovalKind.regularization,
          employeeId: r.employeeId,
          title: 'Attendance correction',
          detail: '${Fmt.date(r.date)}  -  ${Fmt.time(r.requestedIn)} to ${Fmt.time(r.requestedOut)}',
          reason: r.reason,
          status: r.status,
          appliedOn: r.appliedOn,
        ));
      }
    }
    items.sort((a, b) {
      if (a.status == RequestStatus.pending && b.status != RequestStatus.pending) return -1;
      if (b.status == RequestStatus.pending && a.status != RequestStatus.pending) return 1;
      return b.appliedOn.compareTo(a.appliedOn);
    });
    return items;
  }

  int pendingCount({Set<String>? employeeIds}) =>
      approvals(employeeIds: employeeIds).where((a) => a.status == RequestStatus.pending).length;

  /// Approves or rejects a request. Returns false when the server rejected
  /// the review (the local status is restored and an error is reported).
  Future<bool> reviewApproval(ApprovalItem item, RequestStatus status) async {
    final undo = <void Function()>[];
    final ok = await _persist(() => _applyReview(item, status, undo), undo: () {
      for (final u in undo.reversed) {
        u();
      }
    });
    if (!ok) return false;
    final verb = status == RequestStatus.approved ? 'Approved' : 'Rejected';
    _audit('$verb ${item.kind.label.toLowerCase()} request', '${nameOf(item.employeeId)} - ${item.title}',
        status == RequestStatus.approved ? Icons.check_circle_outline : Icons.cancel_outlined);
    notifyListeners();
    return true;
  }

  Future<void> _applyReview(ApprovalItem item, RequestStatus status, List<void Function()> undo) async {
    switch (item.kind) {
      case ApprovalKind.leave:
        {
          final r = leaves.firstWhere((l) => l.id == item.id);
          final prev = r.status;
          r.status = status;
          undo.add(() => r.status = prev);
          await _repo.saveLeave(r);
        }
      case ApprovalKind.wfh:
        {
          final r = wfhRequests.firstWhere((w) => w.id == item.id);
          final prev = r.status;
          r.status = status;
          undo.add(() => r.status = prev);
          await _repo.saveWfh(r);
        }
      case ApprovalKind.regularization:
        {
        final r = regularizations.firstWhere((x) => x.id == item.id);
        final prev = r.status;
        r.status = status;
        undo.add(() => r.status = prev);
        if (status == RequestStatus.approved) {
          final existing = recordOn(r.employeeId, r.date);
          if (existing != null) {
            final (oIn, oOut, oStatus, oNote) = (existing.checkIn, existing.checkOut, existing.status, existing.note);
            undo.add(() => existing
              ..checkIn = oIn
              ..checkOut = oOut
              ..status = oStatus
              ..note = oNote);
            existing.checkIn = r.requestedIn;
            existing.checkOut = r.requestedOut;
            existing.status = AttendanceStatus.present;
            existing.note = 'Regularized';
            await _repo.saveAttendance(existing);
          } else {
            final e = employeeById(r.employeeId);
            final rec = Attendance(
              id: 'A-${r.employeeId}-${r.date.year}${r.date.month.toString().padLeft(2, '0')}${r.date.day.toString().padLeft(2, '0')}',
              employeeId: r.employeeId,
              date: dateOnly(r.date),
              status: AttendanceStatus.present,
              checkIn: r.requestedIn,
              checkOut: r.requestedOut,
              office: e?.branch ?? 'Office',
              note: 'Regularized',
            );
            attendance.add(rec);
            undo.add(() => attendance.remove(rec));
            await _repo.saveAttendance(rec);
          }
        }
        await _repo.saveRegularization(r);
        }
    }
  }

  // --------------------------------------------------------------- employees

  Future<Employee> addEmployee({
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String department,
    required String designation,
    required String branch,
    required String shift,
    required String? managerId,
    required DateTime joinDate,
    required String employmentType,
  }) async {
    final next = employees
            .map((e) => int.tryParse(e.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
            .fold<int>(1000, (a, b) => a > b ? a : b) +
        1;
    final e = Employee(
      id: 'E$next',
      name: name,
      email: email,
      phone: phone,
      department: department,
      designation: designation,
      branch: branch,
      shift: shift,
      managerId: managerId,
      joinDate: joinDate,
      gender: gender,
      employmentType: employmentType,
      address: branch,
    );
    employees.add(e);
    try {
      await _repo.saveEmployee(e, isNew: true);
    } catch (err) {
      // Rethrown so the Add Employee form stays open with the server message.
      employees.remove(e);
      notifyListeners();
      throw err is RepoWriteException ? err : RepoWriteException('Could not add the employee. Please try again.');
    }
    _audit('Added employee', '$name ($designation)', Icons.person_add_alt_outlined);
    notifyListeners();
    return e;
  }

  Future<bool> toggleEmployeeActive(Employee e) async {
    e.active = !e.active;
    notifyListeners();
    if (!await _persist(() => _repo.saveEmployee(e), undo: () => e.active = !e.active)) return false;
    _audit(e.active ? 'Activated employee' : 'Deactivated employee', e.name,
        e.active ? Icons.person_outline : Icons.person_off_outlined);
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------- organisation setup

  void addDepartment(String name, String head, String description) {
    final d = Department(id: _newId('D'), name: name, head: head, description: description);
    departments.add(d);
    final log = _audit('Created department', name, Icons.account_tree_outlined);
    unawaited(_persist(() => _repo.saveDepartment(d, isNew: true), undo: () {
      departments.remove(d);
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  /// Sets (or clears, with nulls) a branch's office location / geofence.
  Future<bool> setBranchLocation(Branch b, {double? latitude, double? longitude, int? radiusMeters}) async {
    final (oLat, oLng, oRadius) = (b.latitude, b.longitude, b.geofenceRadiusMeters);
    b
      ..latitude = latitude
      ..longitude = longitude
      ..geofenceRadiusMeters = radiusMeters;
    notifyListeners();
    final ok = await _persist(() => _repo.saveBranch(b), undo: () {
      b
        ..latitude = oLat
        ..longitude = oLng
        ..geofenceRadiusMeters = oRadius;
    });
    if (ok) {
      _audit(latitude == null ? 'Removed branch geofence' : 'Set branch geofence', b.name, Icons.location_on_outlined);
      notifyListeners();
    }
    return ok;
  }

  // ------------------------------------------------------ company settings

  /// Loads organisation settings (Super Admin). Throws [RepoWriteException]
  /// with a user-facing message when they can't be read.
  Future<Map<String, String>> loadCompanySettings() => _repo.loadCompanySettings();

  Future<bool> saveCompanySettings(Map<String, Object?> settings) async {
    final ok = await _persist(() => _repo.saveCompanySettings(settings));
    if (ok) {
      _audit('Updated organisation settings', '${settings.length} setting(s)', Icons.settings_outlined);
      notifyListeners();
    }
    return ok;
  }

  void addBranch({
    required String name,
    required String city,
    required String address,
    required String hours,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) {
    final b = Branch(
      id: _newId('B'),
      name: name,
      city: city,
      address: address,
      workingHours: hours,
      latitude: latitude,
      longitude: longitude,
      geofenceRadiusMeters: radiusMeters,
    );
    branches.add(b);
    final log = _audit('Created branch', name, Icons.apartment);
    unawaited(_persist(() => _repo.saveBranch(b, isNew: true), undo: () {
      branches.remove(b);
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  void saveShift({
    Shift? existing,
    required String name,
    required int sh,
    required int sm,
    required int eh,
    required int em,
    required int grace,
  }) {
    if (existing != null) {
      final (oName, oSh, oSm, oEh, oEm, oGrace) =
          (existing.name, existing.startHour, existing.startMinute, existing.endHour, existing.endMinute, existing.graceMinutes);
      existing
        ..name = name
        ..startHour = sh
        ..startMinute = sm
        ..endHour = eh
        ..endMinute = em
        ..graceMinutes = grace;
      final log = _audit('Updated shift', name, Icons.schedule);
      unawaited(_persist(() => _repo.saveShift(existing), undo: () {
        existing
          ..name = oName
          ..startHour = oSh
          ..startMinute = oSm
          ..endHour = oEh
          ..endMinute = oEm
          ..graceMinutes = oGrace;
        auditLogs.remove(log);
      }));
    } else {
      final s = Shift(id: _newId('S'), name: name, startHour: sh, startMinute: sm, endHour: eh, endMinute: em, graceMinutes: grace);
      shifts.add(s);
      final log = _audit('Created shift', name, Icons.schedule);
      unawaited(_persist(() => _repo.saveShift(s, isNew: true), undo: () {
        shifts.remove(s);
        auditLogs.remove(log);
      }));
    }
    notifyListeners();
  }

  void addHoliday(String name, DateTime date, String type) {
    final h = Holiday(id: _newId('H'), date: date, name: name, type: type);
    holidays.add(h);
    holidays.sort((a, b) => a.date.compareTo(b.date));
    final log = _audit('Added holiday', '$name (${Fmt.date(date)})', Icons.event_outlined);
    unawaited(_persist(() => _repo.saveHoliday(h), undo: () {
      holidays.remove(h);
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  void removeHoliday(Holiday h) {
    holidays.removeWhere((x) => x.id == h.id);
    final log = _audit('Removed holiday', h.name, Icons.event_busy_outlined);
    unawaited(_persist(() => _repo.deleteHoliday(h), undo: () {
      holidays
        ..add(h)
        ..sort((a, b) => a.date.compareTo(b.date));
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  // ----------------------------------------------------------- announcements

  List<Announcement> get publishedAnnouncements {
    final l = announcements.where((a) => a.published).toList();
    l.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return l;
  }

  void saveAnnouncement({
    Announcement? existing,
    required String title,
    required String body,
    required String category,
    required String audience,
    required bool publish,
  }) {
    if (existing != null) {
      final (oTitle, oBody, oCategory, oAudience, oPublished) =
          (existing.title, existing.body, existing.category, existing.audience, existing.published);
      existing
        ..title = title
        ..body = body
        ..category = category
        ..audience = audience
        ..published = publish;
      final log = _audit('Edited announcement', title, Icons.edit_outlined);
      unawaited(_persist(() => _repo.saveAnnouncement(existing), undo: () {
        existing
          ..title = oTitle
          ..body = oBody
          ..category = oCategory
          ..audience = oAudience
          ..published = oPublished;
        auditLogs.remove(log);
      }));
    } else {
      final a = Announcement(
        id: _newId('AN'),
        title: title,
        body: body,
        category: category,
        date: DateTime.now(),
        author: me.name,
        audience: audience,
        published: publish,
      );
      announcements.add(a);
      final log = _audit(publish ? 'Published announcement' : 'Saved announcement draft', title, Icons.campaign_outlined);
      unawaited(_persist(() => _repo.saveAnnouncement(a, isNew: true), undo: () {
        announcements.remove(a);
        auditLogs.remove(log);
      }));
    }
    notifyListeners();
  }

  void togglePublish(Announcement a) {
    a.published = !a.published;
    final log = _audit(a.published ? 'Published announcement' : 'Unpublished announcement', a.title, Icons.campaign_outlined);
    if (a.published) {
      unawaited(_persist(() => _repo.publishAnnouncement(a), undo: () {
        a.published = false;
        auditLogs.remove(log);
      }));
    }
    notifyListeners();
  }

  void deleteAnnouncement(Announcement a) {
    announcements.removeWhere((x) => x.id == a.id);
    _audit('Deleted announcement', a.title, Icons.delete_outline);
    notifyListeners();
  }

  // ------------------------------------------------------------ notifications

  int get unreadCount => notifications.where((n) => !n.read).length;

  void markRead(AppNotification n) {
    if (n.read) return;
    n.read = true;
    unawaited(_persist(() => _repo.markNotificationRead(n), undo: () => n.read = false));
    notifyListeners();
  }

  void markAllRead() {
    final unread = notifications.where((n) => !n.read).toList();
    for (final n in unread) {
      n.read = true;
    }
    unawaited(_persist(() => _repo.markAllNotificationsRead(), undo: () {
      for (final n in unread) {
        n.read = false;
      }
    }));
    notifyListeners();
  }

  void _addNotification(String title, String body, String type) {
    notifications.insert(
        0, AppNotification(id: _newId('N'), title: title, body: body, time: DateTime.now(), type: type));
  }

  // --------------------------------------------------------------- documents

  void addDocument(String title, String category) {
    documents.insert(
        0, DocumentItem(id: _newId('DOC'), title: title, category: category, updated: DateTime.now(), size: '1.0 MB'));
    _audit('Uploaded document', title, Icons.upload_file_outlined);
    notifyListeners();
  }

  void deleteDocument(DocumentItem d) {
    final index = documents.indexWhere((x) => x.id == d.id);
    documents.removeWhere((x) => x.id == d.id);
    final log = _audit('Deleted document', d.title, Icons.delete_outline);
    unawaited(_persist(() => _repo.deleteDocument(d), undo: () {
      documents.insert(index < 0 ? 0 : index.clamp(0, documents.length), d);
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  // ---------------------------------------------------------------- expenses

  List<Expense> expensesFor(String empId) {
    final l = expenses.where((e) => e.employeeId == empId).toList();
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  void submitExpense({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    required bool receipt,
    required String notes,
  }) {
    final e = Expense(
      id: _newId('X'),
      employeeId: _meId,
      title: title,
      category: category,
      amount: amount,
      date: date,
      hasReceipt: receipt,
      notes: notes,
    );
    expenses.add(e);
    unawaited(_persist(() => _repo.saveExpense(e, isNew: true), undo: () => expenses.remove(e)).then((ok) {
      if (!ok) return;
      _addNotification('Expense claim submitted', '$title - ${Fmt.money(amount)} is pending approval.', 'system');
      notifyListeners();
    }));
    notifyListeners();
  }

  void reviewExpense(Expense e, String status) {
    final prev = e.status;
    e.status = status;
    final log = _audit('$status expense claim', '${nameOf(e.employeeId)} - ${e.title}',
        status == 'Rejected' ? Icons.cancel_outlined : Icons.check_circle_outline);
    unawaited(_persist(() => _repo.saveExpense(e), undo: () {
      e.status = prev;
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  // ------------------------------------------------------------------ assets

  List<Asset> assetsFor(String empId) => assets.where((a) => a.assignedTo == empId).toList();

  void addAsset({required String name, required String type, required String serial}) {
    final a = Asset(id: _newId('AS'), name: name, type: type, serial: serial);
    assets.add(a);
    final log = _audit('Added asset', '$name ($serial)', Icons.inventory_2_outlined);
    unawaited(_persist(() => _repo.saveAsset(a, isNew: true), undo: () {
      assets.remove(a);
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  void assignAsset(Asset a, String? empId) {
    final (oTo, oStatus, oOn) = (a.assignedTo, a.status, a.assignedOn);
    a.assignedTo = empId;
    a.status = empId == null ? 'Available' : 'Assigned';
    a.assignedOn = empId == null ? null : DateTime.now();
    final log = _audit(empId == null ? 'Unassigned asset' : 'Assigned asset',
        empId == null ? a.name : '${a.name} to ${nameOf(empId)}', Icons.laptop_mac);
    unawaited(_persist(() => _repo.assignAsset(a, empId), undo: () {
      a
        ..assignedTo = oTo
        ..status = oStatus
        ..assignedOn = oOn;
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  void setAssetStatus(Asset a, String status) {
    final (oTo, oStatus) = (a.assignedTo, a.status);
    a.status = status;
    if (status != 'Assigned') a.assignedTo = null;
    final log = _audit('Updated asset status', '${a.name} - $status', Icons.build_outlined);
    unawaited(_persist(() => _repo.saveAsset(a), undo: () {
      a
        ..assignedTo = oTo
        ..status = oStatus;
      auditLogs.remove(log);
    }));
    notifyListeners();
  }

  // ----------------------------------------------------------------- tickets

  List<Ticket> ticketsFor(String empId) {
    final l = tickets.where((t) => t.employeeId == empId).toList();
    l.sort((a, b) => b.created.compareTo(a.created));
    return l;
  }

  void createTicket({required String subject, required String category, required String priority, required String message}) {
    final t = Ticket(
      id: 'T-${1043 + tickets.length}',
      employeeId: _meId,
      subject: subject,
      category: category,
      priority: priority,
      created: DateTime.now(),
    );
    t.messages.add(TicketMessage(fromMe: true, sender: me.name, text: message, time: DateTime.now()));
    tickets.add(t);
    unawaited(_persist(() => _repo.saveTicket(t, isNew: true), undo: () => tickets.remove(t)));
    notifyListeners();
  }

  void replyTicket(Ticket t, String text) {
    final msg = TicketMessage(fromMe: true, sender: me.name, text: text, time: DateTime.now());
    t.messages.add(msg);
    unawaited(_persist(() => _repo.replyTicket(t, text), undo: () => t.messages.remove(msg)));
    notifyListeners();
    // Simulated support agent reply (demo mode only).
    if (_repo is! MockAppRepository) return;
    Future<void>.delayed(const Duration(seconds: 2), () {
      t.messages.add(TicketMessage(
        fromMe: false,
        sender: 'Support Team',
        text: 'Thanks for the update. We are looking into this and will get back to you shortly.',
        time: DateTime.now(),
      ));
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------- calendar

  List<CalendarEntry> calendarEntries() {
    final list = <CalendarEntry>[];
    for (final h in holidays) {
      list.add(CalendarEntry(date: dateOnly(h.date), title: h.name, type: 'Holiday', color: const Color(0xFF1F6F66), subtitle: h.type));
    }
    for (final m in meetings.where((m) => m.participantIds.contains(_meId))) {
      list.add(CalendarEntry(
          date: dateOnly(m.start),
          title: m.title,
          type: 'Meeting',
          color: const Color(0xFF175CD3),
          subtitle: '${Fmt.time(m.start)} - ${Fmt.time(m.end)}'));
    }
    for (final l in leaves.where((l) => l.employeeId == _meId && l.status != RequestStatus.rejected)) {
      var d = dateOnly(l.from);
      while (!d.isAfter(dateOnly(l.to))) {
        if (d.weekday < 6) {
          list.add(CalendarEntry(
              date: d,
              title: l.type,
              type: 'Leave',
              color: const Color(0xFF6941C6),
              subtitle: l.status.name == 'pending' ? 'Pending approval' : 'Approved'));
        }
        d = DateTime(d.year, d.month, d.day + 1);
      }
    }
    for (final w in wfhRequests.where((w) => w.employeeId == _meId && w.status != RequestStatus.rejected)) {
      var d = dateOnly(w.from);
      while (!d.isAfter(dateOnly(w.to))) {
        if (d.weekday < 6) {
          list.add(CalendarEntry(
              date: d,
              title: 'Work from home',
              type: 'WFH',
              color: const Color(0xFFB54708),
              subtitle: w.status == RequestStatus.pending ? 'Pending approval' : 'Approved'));
        }
        d = DateTime(d.year, d.month, d.day + 1);
      }
    }
    for (final a in announcements.where((a) => a.published && a.category == 'Event')) {
      list.add(CalendarEntry(date: dateOnly(a.date), title: a.title, type: 'Event', color: const Color(0xFFC11574)));
    }
    return list;
  }

  List<Meeting> get upcomingMeetings {
    final now = DateTime.now();
    final l = meetings.where((m) => m.participantIds.contains(_meId) && m.end.isAfter(now)).toList();
    l.sort((a, b) => a.start.compareTo(b.start));
    return l;
  }

  // ------------------------------------------------------------------- audit

  AuditLog _audit(String action, String target, IconData icon) {
    final log = AuditLog(id: _newId('AU'), time: DateTime.now(), actor: me.name, action: action, target: target, icon: icon);
    auditLogs.insert(0, log);
    return log;
  }
}
