import 'dart:async';

import 'package:office_management/core/common.dart';

import '../repositories/app_repository.dart';

/// Holds all demo data and business rules.
///
/// Flow: UI -> AppController -> AppRepository (mock now, REST API later).
class AppController extends ChangeNotifier {
  AppController(this._repo);

  final AppRepository _repo;

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
    return load();
  }

  void reset() {
    _role = null;
    _meId = '';
    loaded = false;
    loading = false;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final s = await _repo.load();
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
    } catch (e) {
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

  Future<void> checkIn() async {
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
    );
    attendance.removeWhere((a) => a.id == rec.id);
    attendance.add(rec);
    await _repo.saveAttendance(rec);
    _addNotification('Checked in', 'You checked in at ${Fmt.time(now)}.', 'attendance');
    notifyListeners();
  }

  Future<void> startBreak() async {
    final a = myToday;
    if (a == null || workState != WorkState.working) return;
    a.breaks.add(AttendanceBreak(start: DateTime.now()));
    await _repo.saveAttendance(a);
    notifyListeners();
  }

  Future<void> endBreak() async {
    final a = myToday;
    if (a == null || workState != WorkState.onBreak) return;
    a.breaks.last.end = DateTime.now();
    await _repo.saveAttendance(a);
    notifyListeners();
  }

  Future<void> checkOut() async {
    final a = myToday;
    if (a == null || a.checkIn == null || a.checkOut != null) return;
    final now = DateTime.now();
    if (a.breaks.isNotEmpty && a.breaks.last.end == null) a.breaks.last.end = now;
    a.checkOut = now;
    await _repo.saveAttendance(a);
    _addNotification('Checked out', 'Day completed - ${Fmt.duration(a.worked)} worked.', 'attendance');
    notifyListeners();
  }

  /// Simulated QR scan: toggles between check-in and check-out.
  Future<String> qrScan() async {
    switch (workState) {
      case WorkState.notStarted:
        await checkIn();
        return 'Checked in successfully at ${Fmt.time(myToday?.checkIn)}.';
      case WorkState.working:
      case WorkState.onBreak:
        await checkOut();
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

  Future<void> submitLeave({
    required String type,
    required DateTime from,
    required DateTime to,
    required bool halfDay,
    required String reason,
    required bool attachment,
  }) async {
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
    await _repo.saveLeave(r);
    _addNotification('Leave request submitted', '$type for ${r.days % 1 == 0 ? r.days.toInt() : r.days} day(s) is pending approval.', 'leave');
    notifyListeners();
  }

  Future<void> submitWfh({required DateTime from, required DateTime to, required String reason}) async {
    final r = WFHRequest(id: _newId('W'), employeeId: _meId, from: from, to: to, reason: reason, appliedOn: DateTime.now());
    wfhRequests.add(r);
    await _repo.saveWfh(r);
    _addNotification('WFH request submitted', 'Your work from home request is pending approval.', 'leave');
    notifyListeners();
  }

  Future<void> submitRegularization({
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
    await _repo.saveRegularization(r);
    _addNotification('Regularization submitted', 'Your attendance correction is with your manager.', 'attendance');
    notifyListeners();
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

  Future<void> reviewApproval(ApprovalItem item, RequestStatus status) async {
    switch (item.kind) {
      case ApprovalKind.leave:
        {
          final r = leaves.firstWhere((l) => l.id == item.id);
          r.status = status;
          await _repo.saveLeave(r);
        }
      case ApprovalKind.wfh:
        {
          final r = wfhRequests.firstWhere((w) => w.id == item.id);
          r.status = status;
          await _repo.saveWfh(r);
        }
      case ApprovalKind.regularization:
        {
        final r = regularizations.firstWhere((x) => x.id == item.id);
        r.status = status;
        if (status == RequestStatus.approved) {
          final existing = recordOn(r.employeeId, r.date);
          if (existing != null) {
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
            await _repo.saveAttendance(rec);
          }
        }
        await _repo.saveRegularization(r);
        }
    }
    final verb = status == RequestStatus.approved ? 'Approved' : 'Rejected';
    _audit('$verb ${item.kind.label.toLowerCase()} request', '${nameOf(item.employeeId)} - ${item.title}',
        status == RequestStatus.approved ? Icons.check_circle_outline : Icons.cancel_outlined);
    notifyListeners();
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
    await _repo.saveEmployee(e, isNew: true);
    _audit('Added employee', '$name ($designation)', Icons.person_add_alt_outlined);
    notifyListeners();
    return e;
  }

  Future<void> toggleEmployeeActive(Employee e) async {
    e.active = !e.active;
    await _repo.saveEmployee(e);
    _audit(e.active ? 'Activated employee' : 'Deactivated employee', e.name,
        e.active ? Icons.person_outline : Icons.person_off_outlined);
    notifyListeners();
  }

  // ------------------------------------------------------- organisation setup

  void addDepartment(String name, String head, String description) {
    final d = Department(id: _newId('D'), name: name, head: head, description: description);
    departments.add(d);
    unawaited(_repo.saveDepartment(d, isNew: true));
    _audit('Created department', name, Icons.account_tree_outlined);
    notifyListeners();
  }

  void addBranch({required String name, required String city, required String address, required String hours}) {
    final b = Branch(id: _newId('B'), name: name, city: city, address: address, workingHours: hours);
    branches.add(b);
    unawaited(_repo.saveBranch(b, isNew: true));
    _audit('Created branch', name, Icons.apartment);
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
      existing
        ..name = name
        ..startHour = sh
        ..startMinute = sm
        ..endHour = eh
        ..endMinute = em
        ..graceMinutes = grace;
      unawaited(_repo.saveShift(existing));
      _audit('Updated shift', name, Icons.schedule);
    } else {
      final s = Shift(id: _newId('S'), name: name, startHour: sh, startMinute: sm, endHour: eh, endMinute: em, graceMinutes: grace);
      shifts.add(s);
      unawaited(_repo.saveShift(s, isNew: true));
      _audit('Created shift', name, Icons.schedule);
    }
    notifyListeners();
  }

  void addHoliday(String name, DateTime date, String type) {
    final h = Holiday(id: _newId('H'), date: date, name: name, type: type);
    holidays.add(h);
    holidays.sort((a, b) => a.date.compareTo(b.date));
    unawaited(_repo.saveHoliday(h));
    _audit('Added holiday', '$name (${Fmt.date(date)})', Icons.event_outlined);
    notifyListeners();
  }

  void removeHoliday(Holiday h) {
    holidays.removeWhere((x) => x.id == h.id);
    unawaited(_repo.deleteHoliday(h));
    _audit('Removed holiday', h.name, Icons.event_busy_outlined);
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
      existing
        ..title = title
        ..body = body
        ..category = category
        ..audience = audience
        ..published = publish;
      unawaited(_repo.saveAnnouncement(existing));
      _audit('Edited announcement', title, Icons.edit_outlined);
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
      unawaited(_repo.saveAnnouncement(a, isNew: true));
      _audit(publish ? 'Published announcement' : 'Saved announcement draft', title, Icons.campaign_outlined);
    }
    notifyListeners();
  }

  void togglePublish(Announcement a) {
    a.published = !a.published;
    if (a.published) unawaited(_repo.publishAnnouncement(a));
    _audit(a.published ? 'Published announcement' : 'Unpublished announcement', a.title, Icons.campaign_outlined);
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
    n.read = true;
    unawaited(_repo.markNotificationRead(n));
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    unawaited(_repo.markAllNotificationsRead());
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
    documents.removeWhere((x) => x.id == d.id);
    unawaited(_repo.deleteDocument(d));
    _audit('Deleted document', d.title, Icons.delete_outline);
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
    unawaited(_repo.saveExpense(e, isNew: true));
    _addNotification('Expense claim submitted', '$title - ${Fmt.money(amount)} is pending approval.', 'system');
    notifyListeners();
  }

  void reviewExpense(Expense e, String status) {
    e.status = status;
    unawaited(_repo.saveExpense(e));
    _audit('$status expense claim', '${nameOf(e.employeeId)} - ${e.title}',
        status == 'Rejected' ? Icons.cancel_outlined : Icons.check_circle_outline);
    notifyListeners();
  }

  // ------------------------------------------------------------------ assets

  List<Asset> assetsFor(String empId) => assets.where((a) => a.assignedTo == empId).toList();

  void addAsset({required String name, required String type, required String serial}) {
    final a = Asset(id: _newId('AS'), name: name, type: type, serial: serial);
    assets.add(a);
    unawaited(_repo.saveAsset(a, isNew: true));
    _audit('Added asset', '$name ($serial)', Icons.inventory_2_outlined);
    notifyListeners();
  }

  void assignAsset(Asset a, String? empId) {
    a.assignedTo = empId;
    a.status = empId == null ? 'Available' : 'Assigned';
    a.assignedOn = empId == null ? null : DateTime.now();
    unawaited(_repo.assignAsset(a, empId));
    _audit(empId == null ? 'Unassigned asset' : 'Assigned asset',
        empId == null ? a.name : '${a.name} to ${nameOf(empId)}', Icons.laptop_mac);
    notifyListeners();
  }

  void setAssetStatus(Asset a, String status) {
    a.status = status;
    if (status != 'Assigned') a.assignedTo = null;
    unawaited(_repo.saveAsset(a));
    _audit('Updated asset status', '${a.name} - $status', Icons.build_outlined);
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
    unawaited(_repo.saveTicket(t, isNew: true));
    notifyListeners();
  }

  void replyTicket(Ticket t, String text) {
    t.messages.add(TicketMessage(fromMe: true, sender: me.name, text: text, time: DateTime.now()));
    unawaited(_repo.replyTicket(t, text));
    notifyListeners();
    // Simulated support agent reply.
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

  void _audit(String action, String target, IconData icon) {
    auditLogs.insert(
        0, AuditLog(id: _newId('AU'), time: DateTime.now(), actor: me.name, action: action, target: target, icon: icon));
  }
}
