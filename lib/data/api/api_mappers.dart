// api_mappers.dart
//
// Converts the Laravel API's JSON shapes (see FLUTTER_API_GUIDE.md §2.4 and the
// resource definitions in §5) into the app's existing domain models so the UI
// layer never has to know whether data came from the mock or the backend.

import '../../models/models.dart';

typedef Json = Map<String, dynamic>;

// ─────────────────────────────────────────────────────────────────────────────
// Small defensive parsers
// ─────────────────────────────────────────────────────────────────────────────

String str(dynamic v, [String fallback = '']) => v == null ? fallback : '$v';

int? intOrNull(dynamic v) => v == null ? null : int.tryParse('$v');

double numOrZero(dynamic v) => v == null ? 0 : (num.tryParse('$v') ?? 0).toDouble();

bool boolOf(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

Json? asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

List<Json> asList(dynamic v) =>
    v is List ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList() : const [];

/// ISO-8601 instant -> local time.
DateTime? dateTimeOrNull(dynamic v) {
  if (v == null) return null;
  final d = DateTime.tryParse('$v');
  return d?.toLocal();
}

/// Date-only fields arrive either as `YYYY-MM-DD` or as a full ISO string with a
/// `date` cast (guide §2.4). Always take the first 10 chars; never convert to
/// local time, or the day can shift.
DateTime dateOnly(dynamic v, [DateTime? fallback]) {
  final s = str(v);
  if (s.length >= 10) {
    final d = DateTime.tryParse(s.substring(0, 10));
    if (d != null) return d;
  }
  return fallback ?? DateTime(1970);
}

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _title(String v) =>
    v.isEmpty ? v : v.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

// ─────────────────────────────────────────────────────────────────────────────
// Enums & status strings
// ─────────────────────────────────────────────────────────────────────────────

AttendanceStatus attendanceStatusOf(String? v) => switch (v) {
      'present' => AttendanceStatus.present,
      'late' => AttendanceStatus.late,
      'half_day' => AttendanceStatus.halfDay,
      'on_leave' => AttendanceStatus.leave,
      'holiday' || 'weekly_off' => AttendanceStatus.holiday,
      'absent' => AttendanceStatus.absent,
      _ => AttendanceStatus.absent,
    };

/// API request statuses -> the app's 3-state RequestStatus. `withdrawn` and
/// `cancelled` have no dedicated value, so they collapse onto `rejected`; the
/// real status text is preserved in `reviewerNote` where useful.
RequestStatus requestStatusOf(String? v) => switch (v) {
      'approved' => RequestStatus.approved,
      'rejected' || 'withdrawn' || 'cancelled' => RequestStatus.rejected,
      _ => RequestStatus.pending,
    };

String expenseStatusOf(String? v) => switch (v) {
      'submitted' => 'Pending',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'paid' => 'Reimbursed',
      'draft' => 'Draft',
      _ => _title(v ?? 'Pending'),
    };

String ticketStatusOf(String? v) => switch (v) {
      'open' => 'Open',
      'assigned' => 'Assigned',
      'in_progress' => 'In Progress',
      'waiting_for_employee' => 'Waiting on you',
      'resolved' => 'Resolved',
      'closed' => 'Closed',
      _ => _title(v ?? 'Open'),
    };

String assetStatusOf(String? v) => switch (v) {
      'assigned' => 'Assigned',
      'maintenance' => 'Under Repair',
      'retired' => 'Retired',
      _ => 'Available',
    };

// ─────────────────────────────────────────────────────────────────────────────
// People & organisation
// ─────────────────────────────────────────────────────────────────────────────

Employee employeeFromStaff(Json j, {UserRole role = UserRole.employee, String shiftName = ''}) {
  final dept = asMap(j['department']);
  final desig = asMap(j['designation']);
  final branch = asMap(j['branch']);
  final status = str(j['employment_status'], 'active');
  return Employee(
    id: str(j['id']),
    name: str(j['name'], '${str(j['first_name'])} ${str(j['last_name'])}'.trim()),
    email: str(j['email']),
    phone: str(j['phone']),
    department: str(dept?['name']),
    designation: str(desig?['title'], str(j['position'])),
    branch: str(branch?['name']),
    shift: shiftName,
    managerId: j['manager_id'] == null ? null : str(j['manager_id']),
    joinDate: dateOnly(j['joining_date'], DateTime.now()),
    active: status != 'terminated' && status != 'resigned',
    role: role,
    address: str(branch?['address']),
  );
}

Department departmentFromJson(Json j) => Department(
      id: str(j['id']),
      name: str(j['name']),
      head: str(asMap(j['head'])?['name']),
      description: str(j['code']),
    );

Branch branchFromJson(Json j) => Branch(
      id: str(j['id']),
      name: str(j['name']),
      address: str(j['address']),
      workingHours: str(j['timezone']),
      city: str(j['address']).contains(',')
          ? str(j['address']).split(',').last.trim()
          : str(j['name']),
    );

Shift shiftFromJson(Json j) {
  List<int> hm(dynamic v) {
    final p = str(v).split(':');
    return [int.tryParse(p.isNotEmpty ? p[0] : '') ?? 9, p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0];
  }

  final s = hm(j['start_time']);
  final e = hm(j['end_time']);
  return Shift(
    id: str(j['id']),
    name: str(j['name']),
    startHour: s[0],
    startMinute: s[1],
    endHour: e[0],
    endMinute: e[1],
    graceMinutes: intOrNull(j['grace_minutes']) ?? 15,
  );
}

Holiday holidayFromJson(Json j) => Holiday(
      id: str(j['id']),
      date: dateOnly(j['holiday_date'], DateTime.now()),
      name: str(j['name']),
      type: _title(str(j['type'], 'public')),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Attendance
// ─────────────────────────────────────────────────────────────────────────────

Attendance attendanceFromJson(
  Json j, {
  List<AttendanceBreak>? breaks,
  String office = 'Office',
}) {
  return Attendance(
    id: str(j['id']),
    employeeId: str(j['staff_id']),
    date: dateOnly(j['work_date'], DateTime.now()),
    status: attendanceStatusOf(str(j['status'], 'absent')),
    checkIn: dateTimeOrNull(j['check_in_at']),
    checkOut: dateTimeOrNull(j['check_out_at']),
    breaks: breaks ?? const [],
    office: office,
    note: str(j['source']) == 'correction' ? 'Regularized' : null,
  );
}

/// Break rows from `/attendance/{id}/breaks` or an `active_break` object.
AttendanceBreak breakFromJson(Json j) => AttendanceBreak(
      start: dateTimeOrNull(j['started_at']) ?? DateTime.now(),
      end: dateTimeOrNull(j['ended_at']),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Leave / WFH / corrections
// ─────────────────────────────────────────────────────────────────────────────

LeaveRequest leaveFromJson(Json j) {
  final type = asMap(j['leave_type']);
  final approvals = asList(j['approvals']);
  String? note;
  for (final a in approvals.reversed) {
    final c = str(a['comments']);
    if (c.isNotEmpty) {
      note = c;
      break;
    }
  }
  final raw = str(j['status']);
  final req = LeaveRequest(
    id: str(j['id']),
    employeeId: str(j['staff_id']),
    type: str(type?['name'], 'Leave'),
    from: dateOnly(j['from_date'], DateTime.now()),
    to: dateOnly(j['to_date'], DateTime.now()),
    halfDay: boolOf(j['partial_day']),
    reason: str(j['reason']),
    status: requestStatusOf(raw),
    appliedOn: dateTimeOrNull(j['created_at']) ?? DateTime.now(),
    hasAttachment: j['attachment'] != null || j['attachment_path'] != null,
    reviewerNote: note,
  );
  if ((raw == 'withdrawn' || raw == 'cancelled') && req.reviewerNote == null) {
    req.reviewerNote = _title(raw);
  }
  return req;
}

WFHRequest wfhFromJson(Json j) => WFHRequest(
      id: str(j['id']),
      employeeId: str(j['staff_id']),
      from: dateOnly(j['from_date'], DateTime.now()),
      to: dateOnly(j['to_date'], DateTime.now()),
      reason: str(j['reason']),
      status: requestStatusOf(str(j['status'])),
      appliedOn: dateTimeOrNull(j['created_at']) ?? dateOnly(j['from_date'], DateTime.now()),
    );

RegularizationRequest correctionFromJson(Json j) {
  final values = asMap(j['requested_values']) ?? const <String, dynamic>{};
  final day = dateOnly(j['work_date'], DateTime.now());
  return RegularizationRequest(
    id: str(j['id']),
    employeeId: str(j['staff_id']),
    date: day,
    requestedIn: dateTimeOrNull(values['check_in_at']) ?? DateTime(day.year, day.month, day.day, 9),
    requestedOut: dateTimeOrNull(values['check_out_at']) ?? DateTime(day.year, day.month, day.day, 18),
    reason: str(j['reason']),
    status: requestStatusOf(str(j['status'])),
    appliedOn: dateTimeOrNull(j['created_at']) ?? DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Announcements / notifications / documents
// ─────────────────────────────────────────────────────────────────────────────

Announcement announcementFromJson(Json j) => Announcement(
      id: str(j['id']),
      title: str(j['title']),
      body: str(j['body']),
      category: _title(str(j['audience'], 'all')),
      date: dateTimeOrNull(j['published_at']) ?? dateTimeOrNull(j['created_at']) ?? DateTime.now(),
      author: str(j['author'], 'HR Team'),
      audience: _title(str(j['audience'], 'all')),
      published: j['published_at'] != null || boolOf(j['is_published']),
    );

AppNotification notificationFromJson(Json j) => AppNotification(
      id: str(j['id']),
      title: str(j['title'], 'Notification'),
      body: str(j['body']),
      time: dateTimeOrNull(j['created_at']) ?? DateTime.now(),
      type: str(j['type'], 'system'),
      read: j['read_at'] != null,
    );

DocumentItem documentFromJson(Json j) {
  final file = str(j['file_name'], str(j['file_path']));
  final ext = file.contains('.') ? file.split('.').last.toUpperCase() : 'FILE';
  return DocumentItem(
    id: str(j['id']),
    title: str(j['title'], file.isEmpty ? 'Document' : file),
    category: _title(str(j['category'], 'general')),
    updated: dateTimeOrNull(j['updated_at']) ?? dateTimeOrNull(j['created_at']) ?? DateTime.now(),
    size: str(j['file_size'], ''),
    extension: ext,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Expenses / meetings / assets / tickets / audit
// ─────────────────────────────────────────────────────────────────────────────

Expense expenseFromJson(Json j) {
  final cat = asMap(j['category']);
  final desc = str(j['description']);
  return Expense(
    id: str(j['id']),
    employeeId: str(j['staff_id']),
    title: desc.isEmpty ? str(cat?['name'], 'Expense') : desc,
    category: str(cat?['name'], 'General'),
    amount: numOrZero(j['amount']),
    date: dateOnly(j['expense_date'], DateTime.now()),
    status: expenseStatusOf(str(j['status'])),
    hasReceipt: j['receipt'] != null || j['receipt_path'] != null,
    notes: desc,
  );
}

Meeting meetingFromJson(Json j) {
  final room = asMap(j['room']);
  final organiser = asMap(j['organiser']);
  final organiserStaff = asMap(organiser?['staff']) ?? organiser;
  final participantIds = <String>[
    for (final p in asList(j['participants']))
      str(asMap(p['staff'])?['id'] ?? p['staff_id'] ?? p['id']),
  ]..removeWhere((e) => e.isEmpty || e == 'null');
  return Meeting(
    id: str(j['id']),
    title: str(j['title']),
    start: dateTimeOrNull(j['starts_at']) ?? DateTime.now(),
    end: dateTimeOrNull(j['ends_at']) ?? DateTime.now(),
    participantIds: participantIds,
    agenda: [if (str(j['description']).isNotEmpty) str(j['description'])],
    link: str(j['meeting_url']),
    location: str(room?['name'], 'Online'),
    organizerId: str(organiserStaff?['id'] ?? j['organiser_id']),
  );
}

Asset assetFromJson(Json j, {String? assignedTo}) {
  final assignment = asMap(j['current_assignment']) ?? asMap(j['assignment']);
  final staff = asMap(assignment?['staff']);
  return Asset(
    id: str(j['id']),
    name: str(j['name']),
    type: str(j['category'], 'Accessory'),
    serial: str(j['serial_number'], str(j['asset_tag'])),
    assignedTo: assignedTo ?? (staff?['id'] ?? assignment?['staff_id'])?.toString(),
    status: assetStatusOf(str(j['status'])),
    assignedOn: dateTimeOrNull(assignment?['assigned_at'] ?? assignment?['created_at']),
  );
}

/// Rows from `GET /staff/{id}/assets` wrap the asset in an assignment record.
Asset staffAssetFromJson(Json j, String ownerId) {
  final asset = asMap(j['asset']) ?? j;
  return assetFromJson(asset, assignedTo: ownerId);
}

Ticket ticketFromJson(Json j, {String? currentUserId}) {
  final cat = asMap(j['category']);
  final messages = <TicketMessage>[
    for (final c in asList(j['comments']))
      TicketMessage(
        fromMe: str(asMap(c['user'])?['id'] ?? c['user_id']) == (currentUserId ?? ''),
        sender: str(asMap(c['user'])?['name'], 'Support'),
        text: str(c['comment']),
        time: dateTimeOrNull(c['created_at']) ?? DateTime.now(),
      ),
  ];
  return Ticket(
    id: str(j['ticket_number'], str(j['id'])),
    employeeId: str(j['staff_id']),
    subject: str(j['subject']),
    category: str(cat?['name'], 'General'),
    priority: _title(str(j['priority'], 'medium')),
    status: ticketStatusOf(str(j['status'])),
    created: dateTimeOrNull(j['created_at']) ?? DateTime.now(),
    messages: messages,
  );
}

AuditLog auditFromJson(Json j) {
  final actor = asMap(j['actor']);
  return AuditLog(
    id: str(j['id']),
    time: dateTimeOrNull(j['created_at']) ?? DateTime.now(),
    actor: str(actor?['name'], 'System'),
    action: _title(str(j['action'], 'updated')),
    target: '${_title(str(j['subject_type'], 'record'))} #${str(j['subject_id'])}',
  );
}
