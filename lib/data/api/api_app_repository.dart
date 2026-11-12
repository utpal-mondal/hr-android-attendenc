// api_app_repository.dart
//
// Live implementation of [AppRepository] backed by the Laravel API
// (see FLUTTER_API_GUIDE.md). Selected at build time via
// `--dart-define=USE_API=true` (see api_config.dart).
//
// Design notes
// ─────────────
// * The contract was designed for a UI that keeps local copies of everything
//   and calls "save" hooks after mutating them. This adapter therefore does
//   *state-diffing*: it remembers which server ids / statuses / attendance
//   phases it last synced and translates each local mutation into the matching
//   endpoint call (check-in vs break vs check-out, submit vs approve vs reject).
// * All list endpoints are fetched in parallel in [load]. Role-scoped
//   endpoints (assets, audit log) are guarded so a 403 just yields an empty
//   list for non-admin users.
// * Write hooks are best-effort: ApiException is caught, the message is stored
//   in [lastError] and logged — the UI stays responsive and shows the change
//   locally until the next refresh.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../../repositories/app_repository.dart';
import 'api_mappers.dart';
import 'office_api_client.dart' hide Json;

class ApiAppRepository implements AppRepository {
  ApiAppRepository(this._api);

  final OfficeApi _api;

  /// Last write-side error message, for diagnostics.
  String? lastError;

  // ----------------------------------------------------------- lookup caches
  final Map<String, int> _deptIds = {};
  final Map<String, int> _desigIds = {};
  final Map<String, int> _branchIds = {};
  final Map<String, int> _shiftIds = {};
  final Map<String, int> _leaveTypeIds = {};
  final Map<String, int> _expenseCatIds = {};
  final Map<String, int> _ticketCatIds = {};
  List<LeaveBalance> _balances = const [];

  // -------------------------------------- local id -> server id for new items
  final Map<String, int> _newStaffIds = {};
  final Map<String, int> _newDeptIds = {};
  final Map<String, int> _newBranchIds = {};
  final Map<String, int> _newShiftIds = {};
  final Map<String, int> _attIds = {};
  final Map<String, int> _leaveIds = {};
  final Map<String, int> _wfhIds = {};
  final Map<String, int> _regIds = {};
  final Map<String, int> _annIds = {};
  final Map<String, int> _expenseIds = {};
  final Map<String, int> _assetIds = {};
  final Map<String, int> _ticketIds = {};
  final Map<String, int> _holidayIds = {};

  // ------------------------------------------------------- state for diffing
  final Map<String, String> _attPhase = {}; // none | in | break | out
  final Map<String, RequestStatus> _leaveStatus = {};
  final Map<String, RequestStatus> _wfhStatus = {};
  final Map<String, RequestStatus> _regStatus = {};
  final Map<String, String> _expenseStatus = {};

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  int? get _myStaffId => _api.currentUser?.staffId;

  Future<T> _guard<T>(Future<T> f, T fallback) async {
    try {
      return await f;
    } on ApiException catch (e) {
      debugPrint('ApiAppRepository: $e');
      return fallback;
    } catch (e) {
      debugPrint('ApiAppRepository: $e');
      return fallback;
    }
  }

  /// Runs a write call, storing/logging failures instead of throwing.
  Future<void> _run(String label, Future<void> Function() call) async {
    try {
      await call();
    } on ApiException catch (e) {
      lastError = e.message;
      debugPrint('ApiAppRepository.$label failed: $e');
    } catch (e) {
      debugPrint('ApiAppRepository.$label failed: $e');
    }
  }

  /// Collects up to [maxPages] pages from a paginated endpoint.
  Future<List<Json>> _allPages(
    Future<PagedResult> Function(int page) fetch, {
    int maxPages = 4,
    int pageSize = 20,
  }) async {
    final out = <Json>[];
    for (var p = 1; p <= maxPages; p++) {
      final page = await fetch(p);
      out.addAll(page.items);
      if (!page.hasMore(pageSize: pageSize)) break;
    }
    return out;
  }

  int? _idOf(Map<String, int> created, String localId) =>
      created[localId] ?? int.tryParse(localId);

  // ─────────────────────────────────────────────────────────────────────────
  // Session / snapshot
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String userIdFor(UserRole role) => _myStaffId?.toString() ?? 'me';

  @override
  List<String> get leaveTypeNames => _leaveTypeIds.keys.toList();

  @override
  List<String> get expenseCategoryNames => _expenseCatIds.keys.toList();

  @override
  List<String> get ticketCategoryNames => _ticketCatIds.keys.toList();

  @override
  Future<AppSnapshot> load() async {
    final me = _api.currentUser;
    final myId = _myStaffId;
    final now = DateTime.now();

    // ── lookups first (needed to resolve names -> ids when mapping) ──
    final lookups = await Future.wait([
      _guard(_api.departments(), const <Json>[]),
      _guard(_api.designations(), const <Json>[]),
      _guard(_api.branches(), const <Json>[]),
      _guard(_api.teams(), const <Json>[]),
      _guard(_api.shifts(), const <Json>[]),
      _guard(_api.leaveTypes(), const <Json>[]),
      _guard(_api.expenseCategories(), const <Json>[]),
      _guard(_api.ticketCategories(), const <Json>[]),
    ]);

    final deptRows = lookups[0];
    final desigRows = lookups[1];
    final branchRows = lookups[2];
    final shiftRows = lookups[4];
    final leaveTypeRows = lookups[5];
    final expenseCatRows = lookups[6];
    final ticketCatRows = lookups[7];

    for (final j in deptRows) {
      _deptIds[str(j['name'])] = intOrNull(j['id']) ?? -1;
    }
    for (final j in desigRows) {
      _desigIds[str(j['title'])] = intOrNull(j['id']) ?? -1;
    }
    for (final j in branchRows) {
      _branchIds[str(j['name'])] = intOrNull(j['id']) ?? -1;
    }
    for (final j in shiftRows) {
      _shiftIds[str(j['name'])] = intOrNull(j['id']) ?? -1;
    }
    for (final j in leaveTypeRows) {
      _leaveTypeIds[str(j['name'])] = intOrNull(j['id']) ?? -1;
    }
    for (final j in expenseCatRows) {
      _expenseCatIds[str(j['name'])] = intOrNull(j['id']) ?? -1;
    }
    for (final j in ticketCatRows) {
      _ticketCatIds[str(j['name'])] = intOrNull(j['id']) ?? -1;
    }

    // ── main data batch ──
    final batch = await Future.wait([
      _guard(_allPages((p) => _api.listStaff(page: p, perPage: 100), pageSize: 100), const <Json>[]),
      _guard(_api.holidays(year: now.year), const <Json>[]),
      _guard(
        _allPages(
          (p) => _api.listAttendance(
              page: p,
              perPage: 100,
              from: ymd(DateTime(now.year, now.month - 3, now.day)),
              to: ymd(now)),
          pageSize: 100,
        ),
        const <Json>[],
      ),
      _guard(
        myId == null ? Future.value(const <String, dynamic>{}) : _api.attendanceToday(),
        const <String, dynamic>{},
      ),
      _guard(_allPages((p) => _api.listLeaveRequests(page: p, perPage: 100), pageSize: 100), const <Json>[]),
      _guard(_allPages((p) => _api.listWfh(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listCorrections(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listAnnouncements(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listNotifications(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listDocuments(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listExpenses(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listMeetings(page: p)), const <Json>[]),
      _guard(_allPages((p) => _api.listTickets(page: p)), const <Json>[]),
      _guard(_api.auditLogs(page: 1), PagedResult(items: const [], currentPage: 1)),
      _guard(_api.leaveBalances(year: now.year), const <Json>[]),
      _guard(
        me?.isAdmin == true ? _allPages((p) => _api.listAssets(page: p)) : Future.value(const <Json>[]),
        const <Json>[],
      ),
      _guard(myId == null ? Future.value(const <Json>[]) : _api.staffAssets(myId), const <Json>[]),
    ]);

    final staffRows = batch[0] as List<Json>;
    final holidayRows = batch[1] as List<Json>;
    final attRows = batch[2] as List<Json>;
    final today = batch[3] as Json;
    final leaveRows = batch[4] as List<Json>;
    final wfhRows = batch[5] as List<Json>;
    final correctionRows = batch[6] as List<Json>;
    final annRows = batch[7] as List<Json>;
    final notifRows = batch[8] as List<Json>;
    final docRows = batch[9] as List<Json>;
    final expenseRows = batch[10] as List<Json>;
    final meetingRows = batch[11] as List<Json>;
    final ticketRows = batch[12] as List<Json>;
    final auditPage = batch[13] as PagedResult;
    final balanceRows = batch[14] as List<Json>;
    final assetRows = batch[15] as List<Json>;
    final myAssetRows = batch[16] as List<Json>;

    // ── my shift name (from today's shift or my open shift assignment) ──
    String myShift = str(asMap(today['shift'])?['name']);
    if (myShift.isEmpty && myId != null) {
      final assignments = await _guard(_api.staffShiftAssignments(myId), const <Json>[]);
      for (final a in assignments) {
        if (a['effective_to'] == null) {
          myShift = str(asMap(a['shift'])?['name']);
          if (myShift.isEmpty) {
            final sid = intOrNull(a['shift_id']);
            for (final e in _shiftIds.entries) {
              if (e.value == sid) myShift = e.key;
            }
          }
          break;
        }
      }
    }

    // ── employees ──
    final myRole = _roleFor(me);
    final employees = <Employee>[
      for (final j in staffRows)
        employeeFromStaff(
          j,
          role: intOrNull(j['id']) == myId ? myRole : UserRole.employee,
          shiftName: intOrNull(j['id']) == myId ? myShift : '',
        ),
    ];
    if (myId != null && !employees.any((e) => e.id == '$myId')) {
      final mine = await _guard(
        _api.getStaff(myId).then((s) => s.raw),
        const <String, dynamic>{},
      );
      if (mine.isNotEmpty) {
        employees.add(employeeFromStaff(mine, role: myRole, shiftName: myShift));
      }
    }
    if (employees.isEmpty || (myId == null && me != null)) {
      // Account without a staff profile — synthesise one so the UI is stable.
      employees.removeWhere((e) => e.id == 'me');
      employees.add(Employee(
        id: 'me',
        name: me?.name ?? 'User',
        email: me?.email ?? '',
        phone: '',
        department: '',
        designation: '',
        branch: '',
        shift: myShift,
        joinDate: DateTime.now(),
        role: myRole,
      ));
    }

    final branchOf = {for (final e in employees) e.id: e.branch};

    // ── attendance (+ today's record merged with breaks) ──
    final attendance = <Attendance>[
      for (final j in attRows)
        attendanceFromJson(j, office: branchOf[str(j['staff_id'])] ?? 'Office'),
    ];
    final todayAtt = asMap(today['attendance']);
    if (todayAtt != null && todayAtt['id'] != null) {
      final serverId = intOrNull(todayAtt['id']);
      final breaks = <AttendanceBreak>[
        for (final b in await _guard(
            serverId == null ? Future.value(const <Json>[]) : _api.listBreaks(serverId), const <Json>[]))
          breakFromJson(b),
      ];
      final active = asMap(todayAtt['active_break']);
      if (active != null && breaks.every((b) => b.end != null)) {
        breaks.add(breakFromJson(active));
      }
      final merged = attendanceFromJson(
        todayAtt,
        breaks: breaks,
        office: myId == null ? 'Office' : (branchOf['$myId'] ?? 'Office'),
      );
      attendance.removeWhere((a) => a.id == merged.id);
      attendance.add(merged);
    }

    // ── map rows into domain models ──
    final leaves = [for (final j in leaveRows) leaveFromJson(j)];
    final wfh = [for (final j in wfhRows) wfhFromJson(j)];
    final regs = [for (final j in correctionRows) correctionFromJson(j)];
    final expenses = [for (final j in expenseRows) expenseFromJson(j)];
    final assets = me?.isAdmin == true
        ? [for (final j in assetRows) assetFromJson(j)]
        : [for (final j in myAssetRows) staffAssetFromJson(j, userIdFor(myRole))];
    final tickets = [for (final j in ticketRows) ticketFromJson(j, currentUserId: me?.id.toString())];

    _balances = [
      for (final j in balanceRows)
        LeaveBalance(
          type: str(asMap(j['leave_type'])?['name'], 'Leave'),
          total: numOrZero(j['opening']) + numOrZero(j['accrued']),
          used: numOrZero(j['used']),
          pending: numOrZero(j['pending']),
        ),
    ];

    // Seed the diffing state so the first save does the right thing.
    for (final a in attendance) {
      _attPhase[a.id] = _phaseOf(a);
    }
    for (final r in leaves) {
      _leaveStatus[r.id] = r.status;
    }
    for (final r in wfh) {
      _wfhStatus[r.id] = r.status;
    }
    for (final r in regs) {
      _regStatus[r.id] = r.status;
    }
    for (final e in expenses) {
      _expenseStatus[e.id] = e.status;
    }
    for (final t in ticketRows) {
      _ticketIds[str(t['ticket_number'], str(t['id']))] = intOrNull(t['id']) ?? -1;
    }

    return AppSnapshot(
      employees: employees,
      departments: [for (final j in deptRows) departmentFromJson(j)],
      branches: [for (final j in branchRows) branchFromJson(j)],
      shifts: [for (final j in shiftRows) shiftFromJson(j)],
      holidays: [for (final j in holidayRows) holidayFromJson(j)],
      attendance: attendance,
      leaves: leaves,
      wfhRequests: wfh,
      regularizations: regs,
      announcements: [for (final j in annRows) announcementFromJson(j)],
      notifications: [for (final j in notifRows) notificationFromJson(j)],
      documents: [for (final j in docRows) documentFromJson(j)],
      payslips: const [], // no payslip endpoint in the API
      expenses: expenses,
      meetings: [for (final j in meetingRows) _meeting(j)],
      assets: assets,
      tickets: tickets,
      auditLogs: [for (final j in auditPage.items) auditFromJson(j)],
      leaveTypeNames: leaveTypeNames,
      leaveBalances: _balances,
    );
  }

  Meeting _meeting(Json j) {
    final m = meetingFromJson(j);
    if (m.organizerId.isNotEmpty && !m.participantIds.contains(m.organizerId)) {
      m.participantIds.add(m.organizerId);
    }
    return m;
  }

  UserRole _roleFor(AppUser? u) {
    if (u == null) return UserRole.employee;
    if (u.isAdmin) return UserRole.hr;
    if (u.isManager) return UserRole.manager;
    return UserRole.employee;
  }

  static String _phaseOf(Attendance a) {
    if (a.checkOut != null) return 'out';
    if (a.breaks.isNotEmpty && a.breaks.last.end == null) return 'break';
    if (a.checkIn != null) return 'in';
    return 'none';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Employees
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveEmployee(Employee e, {bool isNew = false}) => _run('saveEmployee', () async {
        var id = _idOf(_newStaffIds, e.id);
        if (isNew || id == null) {
          final parts = e.name.trim().split(RegExp(r'\s+'));
          final created = await _api.createStaff({
            'employee_code': 'EMP${DateTime.now().millisecondsSinceEpoch % 100000}',
            'first_name': parts.first,
            if (parts.length > 1) 'last_name': parts.sublist(1).join(' '),
            'email': e.email,
            if (e.phone.isNotEmpty) 'phone': e.phone,
            'department_id': _deptIds[e.department],
            'designation_id': _desigIds[e.designation] ?? await _ensureDesignation(e.designation),
            'branch_id': _branchIds[e.branch],
            'manager_id': int.tryParse(e.managerId ?? ''),
            'joining_date': ymd(e.joinDate),
            'employment_status': 'active',
            'create_login': true,
            'role': switch (e.role) {
              UserRole.hr => 'HR Admin',
              UserRole.manager => 'Manager',
              _ => 'Employee',
            },
          });
          id = created.id;
          _newStaffIds[e.id] = id;
          final sid = _shiftIds[e.shift];
          if (sid != null) {
            await _api.assignShift(id, shiftId: sid, effectiveFrom: ymd(e.joinDate));
          }
          return;
        }
        if (!e.active) {
          await _api.deactivateStaff(id);
          return;
        }
        final parts = e.name.trim().split(RegExp(r'\s+'));
        await _api.updateStaff(id, {
          'first_name': parts.first,
          if (parts.length > 1) 'last_name': parts.sublist(1).join(' '),
          'email': e.email,
          if (e.phone.isNotEmpty) 'phone': e.phone,
          'department_id': _deptIds[e.department],
          'branch_id': _branchIds[e.branch],
          'manager_id': int.tryParse(e.managerId ?? ''),
          'employment_status': 'active',
        });
      });

  Future<int?> _ensureDesignation(String title) async {
    if (title.isEmpty) return null;
    final created = await _api.createDesignation(title: title);
    final id = intOrNull(created['id']);
    if (id != null) _desigIds[title] = id;
    return id;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Attendance (check-in / breaks / check-out via phase diffing)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveAttendance(Attendance a) => _run('saveAttendance', () async {
        final prev = _attPhase[a.id] ?? 'none';
        final next = _phaseOf(a);
        var serverId = _idOf(_attIds, a.id);

        // A record that went straight to completed with a "Regularized" note
        // was applied server-side by approving the correction — do not punch.
        final appliedByCorrection = a.note == 'Regularized';

        if (!appliedByCorrection) {
          if (prev == 'none' && next == 'in') {
            final res = await _api.checkIn();
            serverId = intOrNull(res['id']);
            if (serverId != null) _attIds[a.id] = serverId;
          } else if (serverId != null) {
            if (prev == 'in' && next == 'break') {
              await _api.startBreak(serverId);
            } else if (prev == 'break' && next == 'in') {
              await _api.endBreak(serverId);
            } else if (next == 'out') {
              if (prev == 'break') await _api.endBreak(serverId);
              await _api.checkOut();
            }
          }
        }
        _attPhase[a.id] = next;
      });

  // ─────────────────────────────────────────────────────────────────────────
  // Leave / WFH / corrections (submit + approve/reject via status diffing)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveLeave(LeaveRequest r) => _run('saveLeave', () async {
        var sid = _idOf(_leaveIds, r.id);
        if (sid == null) {
          if (r.status != RequestStatus.pending) return;
          final typeId = _leaveTypeIds[r.type] ??
              (_leaveTypeIds.values.isEmpty ? null : _leaveTypeIds.values.first);
          if (typeId == null) return;
          final res = await _api.applyLeave(
            leaveTypeId: typeId,
            fromDate: ymd(r.from),
            toDate: ymd(r.to),
            partialDay: r.halfDay,
            reason: r.reason,
          );
          sid = intOrNull(res['id']);
          if (sid != null) _leaveIds[r.id] = sid;
          _leaveStatus[r.id] = RequestStatus.pending;
          return;
        }
        final prev = _leaveStatus[r.id] ?? RequestStatus.pending;
        if (r.status == prev) return;
        if (r.status == RequestStatus.approved) {
          await _api.approveLeave(sid);
        } else {
          await _api.rejectLeave(sid, comments: r.reviewerNote ?? 'Rejected');
        }
        _leaveStatus[r.id] = r.status;
      });

  @override
  Future<void> saveWfh(WFHRequest r) => _run('saveWfh', () async {
        var sid = _idOf(_wfhIds, r.id);
        if (sid == null) {
          if (r.status != RequestStatus.pending) return;
          final res =
              await _api.requestWfh(fromDate: ymd(r.from), toDate: ymd(r.to), reason: r.reason);
          sid = intOrNull(res['id']);
          if (sid != null) _wfhIds[r.id] = sid;
          _wfhStatus[r.id] = RequestStatus.pending;
          return;
        }
        final prev = _wfhStatus[r.id] ?? RequestStatus.pending;
        if (r.status == prev) return;
        if (r.status == RequestStatus.approved) {
          await _api.approveWfh(sid);
        } else {
          await _api.rejectWfh(sid, comment: 'Rejected');
        }
        _wfhStatus[r.id] = r.status;
      });

  @override
  Future<void> saveRegularization(RegularizationRequest r) =>
      _run('saveRegularization', () async {
        var sid = _idOf(_regIds, r.id);
        if (sid == null) {
          if (r.status != RequestStatus.pending) return;
          final res = await _api.createCorrection(
            workDate: ymd(r.date),
            reason: r.reason,
            checkInAt: r.requestedIn.toUtc().toIso8601String(),
            checkOutAt: r.requestedOut.toUtc().toIso8601String(),
          );
          sid = intOrNull(res['id']);
          if (sid != null) _regIds[r.id] = sid;
          _regStatus[r.id] = RequestStatus.pending;
          return;
        }
        final prev = _regStatus[r.id] ?? RequestStatus.pending;
        if (r.status == prev) return;
        if (r.status == RequestStatus.approved) {
          await _api.approveCorrection(sid);
        } else {
          await _api.rejectCorrection(sid, comment: 'Rejected');
        }
        _regStatus[r.id] = r.status;
      });

  // ─────────────────────────────────────────────────────────────────────────
  // Organisation setup
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveDepartment(Department d, {bool isNew = false}) =>
      _run('saveDepartment', () async {
        final id = _idOf(_newDeptIds, d.id);
        if (isNew || id == null) {
          final res = await _api.createDepartment(
            name: d.name,
            code: d.description.isEmpty ? _code(d.name) : d.description,
            headStaffId: int.tryParse(d.head),
          );
          final newId = intOrNull(res['id']);
          if (newId != null) {
            _newDeptIds[d.id] = newId;
            _deptIds[d.name] = newId;
          }
        } else {
          await _api.updateDepartment(id, {
            'name': d.name,
            'head_staff_id': int.tryParse(d.head),
          });
        }
      });

  @override
  Future<void> saveBranch(Branch b, {bool isNew = false}) =>
      _run('saveBranch', () async {
        final id = _idOf(_newBranchIds, b.id);
        if (isNew || id == null) {
          final res = await _api.createBranch(
            name: b.name,
            code: _code(b.name),
            address: b.address.isEmpty ? b.city : b.address,
            timezone: b.workingHours.isEmpty ? null : b.workingHours,
            status: 'active',
          );
          final newId = intOrNull(res['id']);
          if (newId != null) {
            _newBranchIds[b.id] = newId;
            _branchIds[b.name] = newId;
          }
        } else {
          await _api.updateBranch(id, {
            'name': b.name,
            'address': b.address.isEmpty ? b.city : b.address,
            'timezone': b.workingHours.isEmpty ? null : b.workingHours,
          });
        }
      });

  @override
  Future<void> saveShift(Shift s, {bool isNew = false}) =>
      _run('saveShift', () async {
        String hhmm(int h, int m) =>
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        final id = _idOf(_newShiftIds, s.id);
        if (isNew || id == null) {
          final res = await _api.createShift(
            name: s.name,
            startTime: hhmm(s.startHour, s.startMinute),
            endTime: hhmm(s.endHour, s.endMinute),
            graceMinutes: s.graceMinutes,
          );
          final newId = intOrNull(res['id']);
          if (newId != null) {
            _newShiftIds[s.id] = newId;
            _shiftIds[s.name] = newId;
          }
        } else {
          await _api.updateShift(id, {
            'name': s.name,
            'start_time': hhmm(s.startHour, s.startMinute),
            'end_time': hhmm(s.endHour, s.endMinute),
            'grace_minutes': s.graceMinutes,
          });
        }
      });

  @override
  Future<void> saveHoliday(Holiday h) => _run('saveHoliday', () async {
        final res = await _api.createHoliday(
          holidayDate: ymd(h.date),
          name: h.name,
          type: h.type.toLowerCase(),
        );
        final newId = intOrNull(res['id']);
        if (newId != null) _holidayIds[h.id] = newId;
      });

  @override
  Future<void> deleteHoliday(Holiday h) => _run('deleteHoliday', () async {
        final id = _holidayIds[h.id] ?? int.tryParse(h.id);
        if (id != null) await _api.deleteHoliday(id);
      });

  String _code(String name) {
    final base = name.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final stem = base.length >= 3 ? base.substring(0, 3) : base.padRight(3, 'X');
    return '$stem${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Announcements & notifications
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveAnnouncement(Announcement a, {bool isNew = false}) =>
      _run('saveAnnouncement', () async {
        final id = _idOf(_annIds, a.id);
        final audience = switch (a.audience.toLowerCase()) {
          'branch' => 'branch',
          'department' => 'department',
          _ => 'all',
        };
        if (isNew || id == null) {
          final res = await _api.createAnnouncement(
            title: a.title,
            body: a.body,
            audience: audience,
            publish: a.published,
          );
          final newId = intOrNull(res['id']);
          if (newId != null) _annIds[a.id] = newId;
        } else {
          await _api.updateAnnouncement(id, {'title': a.title, 'body': a.body});
        }
      });

  @override
  Future<void> publishAnnouncement(Announcement a) =>
      _run('publishAnnouncement', () async {
        final id = _idOf(_annIds, a.id);
        if (id != null) await _api.publishAnnouncement(id);
      });

  @override
  Future<void> markNotificationRead(AppNotification n) =>
      _run('markNotificationRead', () async {
        final id = int.tryParse(n.id);
        if (id != null) await _api.markNotificationRead(id);
      });

  @override
  Future<void> markAllNotificationsRead() =>
      _run('markAllNotificationsRead', () => _api.markAllNotificationsRead());

  // ─────────────────────────────────────────────────────────────────────────
  // Documents / expenses / assets / tickets
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteDocument(DocumentItem d) => _run('deleteDocument', () async {
        final id = int.tryParse(d.id);
        if (id != null) await _api.deleteDocument(id);
      });

  @override
  Future<void> saveExpense(Expense e, {bool isNew = false}) =>
      _run('saveExpense', () async {
        var sid = _idOf(_expenseIds, e.id);
        if (sid == null) {
          final catId = _expenseCatIds[e.category] ??
              (_expenseCatIds.values.isEmpty ? null : _expenseCatIds.values.first);
          if (catId == null) return;
          final res = await _api.createExpense(
            categoryId: catId,
            amount: e.amount,
            expenseDate: ymd(e.date),
            description: e.notes.isEmpty ? e.title : '${e.title} — ${e.notes}',
            submit: e.status != 'Draft',
          );
          sid = intOrNull(res['id']);
          if (sid != null) _expenseIds[e.id] = sid;
          _expenseStatus[e.id] = e.status;
          return;
        }
        final prev = _expenseStatus[e.id] ?? e.status;
        if (e.status == prev) return;
        switch (e.status) {
          case 'Approved':
            await _api.approveExpense(sid);
          case 'Rejected':
            await _api.rejectExpense(sid, comments: e.notes.isEmpty ? 'Rejected' : e.notes);
          case 'Reimbursed':
            await _api.markExpensePaid(sid);
          case 'Pending':
            await _api.submitExpense(sid);
        }
        _expenseStatus[e.id] = e.status;
      });

  @override
  Future<void> saveAsset(Asset a, {bool isNew = false}) =>
      _run('saveAsset', () async {
        final id = _idOf(_assetIds, a.id);
        if (isNew || id == null) {
          final res = await _api.createAsset(
            assetTag: a.serial.isEmpty ? _code(a.name) : a.serial,
            name: a.name,
            category: a.type,
            serialNumber: a.serial.isEmpty ? null : a.serial,
          );
          final newId = intOrNull(res['id']);
          if (newId != null) _assetIds[a.id] = newId;
        } else {
          await _api.updateAsset(id, {
            'name': a.name,
            'category': a.type,
            'serial_number': a.serial.isEmpty ? null : a.serial,
            'status': switch (a.status) {
              'Assigned' => 'assigned',
              'Under Repair' => 'maintenance',
              'Retired' => 'retired',
              _ => 'available',
            },
          });
        }
      });

  @override
  Future<void> assignAsset(Asset a, String? employeeId) =>
      _run('assignAsset', () async {
        final id = _idOf(_assetIds, a.id);
        if (id == null) return;
        final staffId = int.tryParse(employeeId ?? '');
        if (staffId == null) {
          await _api.returnAsset(id);
        } else {
          await _api.assignAsset(id, staffId: staffId);
        }
      });

  @override
  Future<void> saveTicket(Ticket t, {bool isNew = false}) =>
      _run('saveTicket', () async {
        if (!isNew) return;
        final res = await _api.createTicket(
          subject: t.subject,
          description: t.messages.isEmpty ? t.subject : t.messages.first.text,
          categoryId: _ticketCatIds[t.category],
          priority: t.priority.toLowerCase(),
        );
        final newId = intOrNull(res['id']);
        if (newId != null) _ticketIds[t.id] = newId;
      });

  @override
  Future<void> replyTicket(Ticket t, String text) => _run('replyTicket', () async {
        final id = _idOf(_ticketIds, t.id);
        if (id != null) await _api.commentOnTicket(id, text);
      });
}
