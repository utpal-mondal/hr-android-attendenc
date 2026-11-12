// office_api_client.dart
//
// Dio-based client for the Office Management API (Laravel + Sanctum, /api/v1).
// One method per endpoint. See FLUTTER_API_GUIDE.md for rules, roles and shapes.
//
// pubspec.yaml:
//   dependencies:
//     dio: ^5.4.0
//     flutter_secure_storage: ^9.0.0
//
// Usage:
//   final api = OfficeApi(baseUrl: 'http://10.0.2.2:8000/api/v1',
//                         onUnauthorized: () => router.go('/login'));
//   await api.restoreSession();
//   final user = await api.login('employee@example.com', 'password');
//   final today = await api.attendanceToday();

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Errors
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Laravel validation errors: field -> list of messages (HTTP 422).
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;

  /// First message for a field, or null.
  String? firstError(String field) {
    final list = fieldErrors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map) {
      final errors = <String, List<String>>{};
      final raw = body['errors'];
      if (raw is Map) {
        raw.forEach((k, v) {
          errors['$k'] = v is List ? v.map((x) => '$x').toList() : ['$v'];
        });
      }
      var message = (body['message'] ?? 'Request failed').toString();
      if (errors.isNotEmpty && status == 422) {
        // Prefer the first concrete field message.
        message = errors.values.first.first;
      }
      return ApiException(message, statusCode: status, fieldErrors: errors);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('The server took too long to respond.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('Cannot reach the server. Check your connection.');
    }
    return ApiException(e.message ?? 'Unexpected error', statusCode: status);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Envelope + pagination
// ─────────────────────────────────────────────────────────────────────────────

class Envelope {
  Envelope(this.message, this.data, this.meta);
  final String message;
  final dynamic data;
  final dynamic meta;

  factory Envelope.from(dynamic body) {
    if (body is Map) {
      return Envelope('${body['message'] ?? ''}', body['data'], body['meta']);
    }
    return Envelope('', body, null);
  }
}

/// A page of results, normalised from the API's four pagination shapes.
class PagedResult {
  PagedResult({
    required this.items,
    required this.currentPage,
    this.lastPage,
    this.total,
    this.perPage,
    this.extra,
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;

  /// null when the endpoint does not report it (leave requests, announcements, tickets).
  final int? lastPage;
  final int? total;
  final int? perPage;

  /// Extra payload, e.g. `unread_count` for notifications.
  final Map<String, dynamic>? extra;

  /// True if more pages may exist. When [lastPage] is unknown, assumes a full
  /// page means "maybe more" (pass the page size you requested, default 20).
  bool hasMore({int pageSize = 20}) {
    if (lastPage != null) return currentPage < lastPage!;
    return items.length >= pageSize;
  }

  static List<Map<String, dynamic>> _list(dynamic v) => (v is List)
      ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  static int? _int(dynamic v) => v == null ? null : int.tryParse('$v');

  /// Shape A: data = list, meta.pagination = {...}
  /// Shape B: data = {current_page, data: [...], last_page, total, per_page}
  /// Shape C: data = {unread_count, notifications: [...], pagination: {...}}
  /// Shape D: data = list, no meta
  factory PagedResult.parse(Envelope env, {int requestedPage = 1}) {
    final d = env.data;
    final meta = env.meta;
    if (d is List) {
      final p = (meta is Map && meta['pagination'] is Map)
          ? meta['pagination'] as Map
          : null;
      return PagedResult(
        items: _list(d),
        currentPage: _int(p?['current_page']) ?? requestedPage,
        lastPage: _int(p?['last_page']),
        total: _int(p?['total']),
        perPage: _int(p?['per_page']),
      );
    }
    if (d is Map && d['notifications'] is List) {
      final p = d['pagination'] is Map ? d['pagination'] as Map : null;
      return PagedResult(
        items: _list(d['notifications']),
        currentPage: _int(p?['current_page']) ?? requestedPage,
        lastPage: _int(p?['last_page']),
        total: _int(p?['total']),
        perPage: _int(p?['per_page']),
        extra: {'unread_count': d['unread_count']},
      );
    }
    if (d is Map && d['data'] is List) {
      return PagedResult(
        items: _list(d['data']),
        currentPage: _int(d['current_page']) ?? requestedPage,
        lastPage: _int(d['last_page']),
        total: _int(d['total']),
        perPage: _int(d['per_page']),
      );
    }
    return PagedResult(items: const [], currentPage: requestedPage);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Core models (the rest of the API is returned as Map<String, dynamic>)
// ─────────────────────────────────────────────────────────────────────────────

class Staff {
  Staff({
    required this.id,
    this.userId,
    this.employeeCode,
    this.name,
    this.email,
    this.phone,
    this.employmentStatus,
    this.departmentId,
    this.designationId,
    this.branchId,
    this.teamId,
    this.managerId,
    this.joiningDate,
    this.raw = const {},
  });

  final int id;
  final int? userId;
  final String? employeeCode;
  final String? name;
  final String? email;
  final String? phone;
  final String? employmentStatus;
  final int? departmentId;
  final int? designationId;
  final int? branchId;
  final int? teamId;
  final int? managerId;
  final String? joiningDate; // YYYY-MM-DD
  final Map<String, dynamic> raw; // includes nested department/branch/... if loaded

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
        id: j['id'] as int,
        userId: j['user_id'] as int?,
        employeeCode: j['employee_code'] as String?,
        name: j['name'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        employmentStatus: j['employment_status'] as String?,
        departmentId: j['department_id'] as int?,
        designationId: j['designation_id'] as int?,
        branchId: j['branch_id'] as int?,
        teamId: j['team_id'] as int?,
        managerId: j['manager_id'] as int?,
        joiningDate: j['joining_date'] as String?,
        raw: j,
      );
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.permissions,
    this.staff,
  });

  final int id; // users.id (NOT staff.id)
  final String name;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final Staff? staff;

  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Iterable<String> r) => r.any(roles.contains);
  bool can(String permission) => permissions.contains(permission);

  bool get isSuperAdmin => hasRole('Super Admin');
  bool get isHrAdmin => hasRole('HR Admin');
  bool get isAdmin => isSuperAdmin || isHrAdmin;
  bool get isManager => hasRole('Manager');
  int? get staffId => staff?.id;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        name: '${j['name'] ?? ''}',
        email: '${j['email'] ?? ''}',
        roles: (j['roles'] as List? ?? const []).map((e) => '$e').toList(),
        permissions:
            (j['permissions'] as List? ?? const []).map((e) => '$e').toList(),
        staff: j['staff'] is Map
            ? Staff.fromJson(Map<String, dynamic>.from(j['staff'] as Map))
            : null,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Client
// ─────────────────────────────────────────────────────────────────────────────

typedef Json = Map<String, dynamic>;

class OfficeApi {
  OfficeApi({
    required String baseUrl,
    this.onUnauthorized,
    this.enableLogging = kDebugMode,
    FlutterSecureStorage? storage,
    Dio? dio,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = _token;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
      onError: (e, handler) async {
        final isLogin = e.requestOptions.path == '/auth/login';
        if (e.response?.statusCode == 401 && !isLogin && _token != null) {
          await clearSession();
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));
    if (enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('$o'),
      ));
    }
  }

  static const _tokenKey = 'office_api_token';

  /// Whether requests/responses are logged to the console (default: debug
  /// builds only).
  final bool enableLogging;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Called after a 401 on an authenticated request (token already cleared).
  final void Function()? onUnauthorized;

  String? _token;
  AppUser? currentUser;

  bool get isLoggedIn => _token != null;

  // ── low-level helpers ──────────────────────────────────────────────────────

  Future<Envelope> _send(
    String method,
    String path, {
    Json? query,
    dynamic body,
  }) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: _clean(query),
        options: Options(method: method),
      );
      return Envelope.from(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Drops null values so they aren't sent as empty query params.
  Json? _clean(Json? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }

  Future<dynamic> _get(String p, {Json? query}) async =>
      (await _send('GET', p, query: query)).data;
  Future<dynamic> _post(String p, [dynamic body]) async =>
      (await _send('POST', p, body: body)).data;
  Future<dynamic> _put(String p, [dynamic body]) async =>
      (await _send('PUT', p, body: body)).data;
  Future<dynamic> _patch(String p, [dynamic body]) async =>
      (await _send('PATCH', p, body: body)).data;
  Future<dynamic> _delete(String p) async => (await _send('DELETE', p)).data;

  Future<PagedResult> _page(String path, {Json? query, int page = 1}) async {
    final env = await _send('GET', path, query: {...?query, 'page': page});
    return PagedResult.parse(env, requestedPage: page);
  }

  /// Laravel serialises an empty collection as `[]`, so treat that as `{}`.
  Json _map(dynamic v) => (v is List && v.isEmpty)
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(v as Map);
  List<Json> _list(dynamic v) =>
      (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  /// Multipart booleans must be 1/0 (Laravel's `boolean` rule rejects "true").
  int _b(bool v) => v ? 1 : 0;

  Future<MultipartFile> _file(String path, {String? filename}) =>
      MultipartFile.fromFile(path, filename: filename);

  // ── session ────────────────────────────────────────────────────────────────

  /// Load a saved token and refresh the user. Returns null if not logged in.
  Future<AppUser?> restoreSession() async {
    _token = await _storage.read(key: _tokenKey);
    if (_token == null) return null;
    try {
      return await me();
    } on ApiException {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    _token = null;
    currentUser = null;
    await _storage.delete(key: _tokenKey);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PUBLIC
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /health
  Future<Json> health() async => _map(await _get('/health'));

  /// POST /auth/login — stores the token securely and returns the user.
  Future<AppUser> login(String email, String password,
      {String deviceName = 'flutter-app'}) async {
    final data = _map(await _post('/auth/login', {
      'email': email,
      'password': password,
      'device_name': deviceName,
    }));
    _token = data['token'] as String;
    await _storage.write(key: _tokenKey, value: _token);
    currentUser = AppUser.fromJson(_map(data['user']));
    return currentUser!;
  }

  /// POST /auth/forgot-password
  Future<void> forgotPassword(String email) async =>
      _post('/auth/forgot-password', {'email': email});

  /// POST /auth/reset-password
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async =>
      _post('/auth/reset-password', {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

  // ═════════════════════════════════════════════════════════════════════════
  // ACCOUNT
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /auth/me
  Future<AppUser> me() async {
    currentUser = AppUser.fromJson(_map(await _get('/auth/me')));
    return currentUser!;
  }

  /// POST /auth/logout (revokes this device's token and clears local session)
  Future<void> logout() async {
    try {
      await _post('/auth/logout');
    } finally {
      await clearSession();
    }
  }

  /// POST /auth/logout-all
  Future<void> logoutAll() async {
    try {
      await _post('/auth/logout-all');
    } finally {
      await clearSession();
    }
  }

  /// POST /auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async =>
      _post('/auth/change-password', {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmation,
      });

  /// PUT /profile
  Future<AppUser> updateProfile({String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    currentUser = AppUser.fromJson(_map(await _put('/profile', body)));
    return currentUser!;
  }

  /// GET /me/permissions -> {roles: [], permissions: []}
  Future<Json> myPermissions() async => _map(await _get('/me/permissions'));

  /// POST /devices — register for push. platform: android | ios | web
  Future<Json> registerDevice({
    required String platform,
    required String deviceIdentifier,
    String? pushToken,
  }) async =>
      _map(await _post('/devices', {
        'platform': platform,
        'device_identifier': deviceIdentifier,
        'push_token': pushToken,
      }));

  /// DELETE /devices/{id}
  Future<void> unregisterDevice(int deviceId) async =>
      _delete('/devices/$deviceId');

  // ═════════════════════════════════════════════════════════════════════════
  // STAFF & ORGANISATION
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /staff
  Future<PagedResult> listStaff({
    String? search,
    int? departmentId,
    int? branchId,
    String? employmentStatus,
    int page = 1,
    int perPage = 20,
  }) =>
      _page('/staff', page: page, query: {
        'search': search,
        'department_id': departmentId,
        'branch_id': branchId,
        'employment_status': employmentStatus,
        'per_page': perPage,
      });

  /// POST /staff  (needs employees.create)
  Future<Staff> createStaff(Json fields) async =>
      Staff.fromJson(_map(await _post('/staff', fields)));
  // fields: employee_code*, first_name*, last_name, email*, phone, department_id,
  // designation_id, branch_id, team_id, manager_id, joining_date,
  // employment_status, create_login (bool), role (required with create_login)

  /// GET /staff/{id}
  Future<Staff> getStaff(int id) async =>
      Staff.fromJson(_map(await _get('/staff/$id')));

  /// PUT /staff/{id}  (needs employees.update)
  Future<Staff> updateStaff(int id, Json fields) async =>
      Staff.fromJson(_map(await _put('/staff/$id', fields)));

  /// DELETE /staff/{id} — deactivates (terminated). Needs employees.deactivate.
  Future<void> deactivateStaff(int id) async => _delete('/staff/$id');

  /// GET /staff/{id}/documents (raw paginator)
  Future<PagedResult> staffDocuments(int staffId, {int page = 1}) =>
      _page('/staff/$staffId/documents', page: page);

  /// GET /staff/{id}/assets (currently assigned, not returned)
  Future<List<Json>> staffAssets(int staffId) async =>
      _list(await _get('/staff/$staffId/assets'));

  /// GET /staff/{id}/shift-assignments
  Future<List<Json>> staffShiftAssignments(int staffId) async =>
      _list(await _get('/staff/$staffId/shift-assignments'));

  /// POST /staff/{id}/shift-assignments  (UI: HR/Admin only)
  Future<Json> assignShift(
    int staffId, {
    required int shiftId,
    required String effectiveFrom, // yyyy-MM-dd
    String? effectiveTo,
  }) async =>
      _map(await _post('/staff/$staffId/shift-assignments', {
        'shift_id': shiftId,
        'effective_from': effectiveFrom,
        'effective_to': effectiveTo,
      }));

  /// DELETE /shift-assignments/{id}  (UI: HR/Admin only)
  Future<void> endShiftAssignment(int assignmentId) async =>
      _delete('/shift-assignments/$assignmentId');

  // ── branches ──
  /// GET /branches
  Future<List<Json>> branches() async => _list(await _get('/branches'));

  /// POST /branches (Super Admin)
  Future<Json> createBranch({
    required String name,
    required String code,
    String? address,
    String? timezone,
    String? status,
  }) async =>
      _map(await _post('/branches', {
        'name': name,
        'code': code,
        'address': address,
        'timezone': timezone,
        'status': status,
      }));

  /// PUT /branches/{id} (Super Admin)
  Future<Json> updateBranch(int id, Json fields) async =>
      _map(await _put('/branches/$id', fields));

  // ── departments ──
  /// GET /departments
  Future<List<Json>> departments() async => _list(await _get('/departments'));

  /// POST /departments (SA/HR)
  Future<Json> createDepartment({
    required String name,
    required String code,
    int? headStaffId,
  }) async =>
      _map(await _post('/departments',
          {'name': name, 'code': code, 'head_staff_id': headStaffId}));

  /// PUT /departments/{id} (SA/HR)
  Future<Json> updateDepartment(int id, Json fields) async =>
      _map(await _put('/departments/$id', fields));

  // ── designations ──
  /// GET /designations
  Future<List<Json>> designations() async => _list(await _get('/designations'));

  /// POST /designations (SA/HR)
  Future<Json> createDesignation({required String title, int? level}) async =>
      _map(await _post('/designations', {'title': title, 'level': level}));

  // ── teams ──
  /// GET /teams
  Future<List<Json>> teams() async => _list(await _get('/teams'));

  /// POST /teams (SA/HR)
  Future<Json> createTeam({
    required String name,
    required int departmentId,
    int? managerId,
  }) async =>
      _map(await _post('/teams', {
        'name': name,
        'department_id': departmentId,
        'manager_id': managerId,
      }));

  // ═════════════════════════════════════════════════════════════════════════
  // ATTENDANCE & BREAKS
  // ═════════════════════════════════════════════════════════════════════════

  Json _punchBody(double? lat, double? lng, int? accuracy, String? deviceId) => {
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
        if (accuracy != null) 'accuracy_meters': accuracy,
        if (deviceId != null) 'device_id': deviceId,
      };

  /// POST /attendance/check-in
  Future<Json> checkIn({
    double? latitude,
    double? longitude,
    int? accuracyMeters,
    String? deviceId,
  }) async =>
      _map(await _post('/attendance/check-in',
          _punchBody(latitude, longitude, accuracyMeters, deviceId)));

  /// POST /attendance/check-out
  Future<Json> checkOut({
    double? latitude,
    double? longitude,
    int? accuracyMeters,
    String? deviceId,
  }) async =>
      _map(await _post('/attendance/check-out',
          _punchBody(latitude, longitude, accuracyMeters, deviceId)));

  /// GET /attendance/today -> {work_date, attendance|null, shift|null}
  Future<Json> attendanceToday() async => _map(await _get('/attendance/today'));

  /// GET /attendance/team/today (Manager/HR/SA)
  Future<List<Json>> teamAttendanceToday() async =>
      _list(await _get('/attendance/team/today'));

  /// GET /attendance/summary
  Future<Json> attendanceSummary({int? staffId, String? from, String? to}) async =>
      _map(await _get('/attendance/summary',
          query: {'staff_id': staffId, 'from': from, 'to': to}));

  /// GET /attendance
  Future<PagedResult> listAttendance({
    int? staffId,
    String? from,
    String? to,
    String? status,
    int page = 1,
    int perPage = 20,
  }) =>
      _page('/attendance', page: page, query: {
        'staff_id': staffId,
        'from': from,
        'to': to,
        'status': status,
        'per_page': perPage,
      });

  /// GET /attendance/{id}
  Future<Json> getAttendance(int id) async => _map(await _get('/attendance/$id'));

  /// GET /attendance/{id}/breaks
  Future<List<Json>> listBreaks(int attendanceId) async =>
      _list(await _get('/attendance/$attendanceId/breaks'));

  /// POST /attendance/{id}/breaks/start
  Future<Json> startBreak(int attendanceId, {String? breakType}) async =>
      _map(await _post('/attendance/$attendanceId/breaks/start',
          {if (breakType != null) 'break_type': breakType}));

  /// POST /attendance/{id}/breaks/end
  Future<Json> endBreak(int attendanceId) async =>
      _map(await _post('/attendance/$attendanceId/breaks/end'));

  // ── corrections ──
  /// GET /attendance/corrections (raw paginator)
  Future<PagedResult> listCorrections({String? status, int page = 1}) =>
      _page('/attendance/corrections', page: page, query: {'status': status});

  /// POST /attendance/corrections
  Future<Json> createCorrection({
    required String workDate, // yyyy-MM-dd
    required String reason,
    String? checkInAt, // ISO-8601
    String? checkOutAt, // ISO-8601
    int? attendanceId,
  }) async =>
      _map(await _post('/attendance/corrections', {
        'work_date': workDate,
        'attendance_id': attendanceId,
        'requested_values': {
          if (checkInAt != null) 'check_in_at': checkInAt,
          if (checkOutAt != null) 'check_out_at': checkOutAt,
        },
        'reason': reason,
      }));

  /// POST /attendance/corrections/{id}/approve (Manager/HR/SA)
  Future<Json> approveCorrection(int id, {String? comment}) async =>
      _map(await _post('/attendance/corrections/$id/approve',
          {if (comment != null) 'comment': comment}));

  /// POST /attendance/corrections/{id}/reject (Manager/HR/SA) — comment required
  Future<Json> rejectCorrection(int id, {required String comment}) async =>
      _map(await _post('/attendance/corrections/$id/reject', {'comment': comment}));

  // ═════════════════════════════════════════════════════════════════════════
  // SHIFTS, HOLIDAYS, CALENDAR
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /shifts
  Future<List<Json>> shifts() async => _list(await _get('/shifts'));

  /// GET /shifts/{id}
  Future<Json> getShift(int id) async => _map(await _get('/shifts/$id'));

  /// POST /shifts (SA/HR) — times as HH:mm
  Future<Json> createShift({
    required String name,
    required String startTime,
    required String endTime,
    int? graceMinutes,
    String? breakPolicy,
    bool? crossesMidnight,
  }) async =>
      _map(await _post('/shifts', {
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
        'grace_minutes': graceMinutes,
        'break_policy': breakPolicy,
        if (crossesMidnight != null) 'crosses_midnight': crossesMidnight,
      }));

  /// PUT /shifts/{id} (SA/HR)
  Future<Json> updateShift(int id, Json fields) async =>
      _map(await _put('/shifts/$id', fields));

  /// GET /holidays
  Future<List<Json>> holidays({int? year, int? branchId}) async =>
      _list(await _get('/holidays',
          query: {'year': year, 'branch_id': branchId}));

  /// POST /holidays (SA/HR) — type: public | restricted | company
  Future<Json> createHoliday({
    required String holidayDate,
    required String name,
    String? type,
    int? branchId,
  }) async =>
      _map(await _post('/holidays', {
        'holiday_date': holidayDate,
        'name': name,
        'type': type,
        'branch_id': branchId,
      }));

  /// PUT /holidays/{id} (SA/HR)
  Future<Json> updateHoliday(int id, Json fields) async =>
      _map(await _put('/holidays/$id', fields));

  /// DELETE /holidays/{id} (SA/HR) — 409 for past holidays
  Future<void> deleteHoliday(int id) async => _delete('/holidays/$id');

  /// GET /calendar?month=YYYY-MM
  Future<Json> calendar({String? month}) async =>
      _map(await _get('/calendar', query: {'month': month}));

  // ═════════════════════════════════════════════════════════════════════════
  // LEAVE
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /leave/types
  Future<List<Json>> leaveTypes() async => _list(await _get('/leave/types'));

  /// GET /leave/balances
  Future<List<Json>> leaveBalances({int? year, int? staffId}) async =>
      _list(await _get('/leave/balances',
          query: {'year': year, 'staff_id': staffId}));

  /// GET /leave/requests (no total/last_page returned)
  Future<PagedResult> listLeaveRequests({String? status, int page = 1, int perPage = 20}) =>
      _page('/leave/requests',
          page: page, query: {'status': status, 'per_page': perPage});

  /// POST /leave/requests (multipart so an attachment can be included)
  Future<Json> applyLeave({
    required int leaveTypeId,
    required String fromDate, // yyyy-MM-dd
    required String toDate,
    bool partialDay = false,
    String? reason,
    String? attachmentPath, // pdf/jpg/png, max 5 MB
  }) async {
    final form = FormData.fromMap({
      'leave_type_id': leaveTypeId,
      'from_date': fromDate,
      'to_date': toDate,
      'partial_day': _b(partialDay),
      if (reason != null) 'reason': reason,
      if (attachmentPath != null) 'attachment': await _file(attachmentPath),
    });
    return _map(await _post('/leave/requests', form));
  }

  /// GET /leave/requests/{id}
  Future<Json> getLeaveRequest(int id) async =>
      _map(await _get('/leave/requests/$id'));

  /// POST /leave/requests/{id}/withdraw (own, pending only)
  Future<Json> withdrawLeave(int id) async =>
      _map(await _post('/leave/requests/$id/withdraw'));

  /// POST /leave/requests/{id}/cancel (approved only)
  Future<Json> cancelLeave(int id) async =>
      _map(await _post('/leave/requests/$id/cancel'));

  /// GET /leave/approvals/pending (Manager/HR/SA) — raw approval rows
  Future<List<Json>> pendingLeaveApprovals() async =>
      _list(await _get('/leave/approvals/pending'));

  /// POST /leave/requests/{id}/approve (Manager/HR/SA)
  Future<Json> approveLeave(int id, {String? comments}) async =>
      _map(await _post('/leave/requests/$id/approve',
          {if (comments != null) 'comments': comments}));

  /// POST /leave/requests/{id}/reject (Manager/HR/SA) — comments required
  Future<Json> rejectLeave(int id, {required String comments}) async =>
      _map(await _post('/leave/requests/$id/reject', {'comments': comments}));

  // ── WFH ──
  /// GET /wfh/requests (raw paginator)
  Future<PagedResult> listWfh({String? status, int page = 1}) =>
      _page('/wfh/requests', page: page, query: {'status': status});

  /// POST /wfh/requests — from_date must be today or later
  Future<Json> requestWfh({
    required String fromDate,
    required String toDate,
    required String reason,
  }) async =>
      _map(await _post('/wfh/requests',
          {'from_date': fromDate, 'to_date': toDate, 'reason': reason}));

  /// POST /wfh/requests/{id}/approve (Manager/HR/SA)
  Future<Json> approveWfh(int id, {String? comment}) async =>
      _map(await _post('/wfh/requests/$id/approve',
          {if (comment != null) 'comment': comment}));

  /// POST /wfh/requests/{id}/reject (Manager/HR/SA) — comment required
  Future<Json> rejectWfh(int id, {required String comment}) async =>
      _map(await _post('/wfh/requests/$id/reject', {'comment': comment}));

  // ═════════════════════════════════════════════════════════════════════════
  // DASHBOARDS & REPORTS
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /dashboard/employee
  Future<Json> employeeDashboard() async => _map(await _get('/dashboard/employee'));

  /// GET /dashboard/manager (Manager/HR/SA)
  Future<Json> managerDashboard() async => _map(await _get('/dashboard/manager'));

  /// GET /dashboard/hr (HR/SA)
  Future<Json> hrDashboard() async => _map(await _get('/dashboard/hr'));

  Json _reportQuery(int? staffId, String? status, String? from, String? to) =>
      {'staff_id': staffId, 'status': status, 'from': from, 'to': to};

  /// GET /reports/attendance
  Future<PagedResult> reportAttendance(
          {int? staffId, String? status, String? from, String? to, int page = 1}) =>
      _page('/reports/attendance',
          page: page, query: _reportQuery(staffId, status, from, to));

  /// GET /reports/late-arrivals
  Future<PagedResult> reportLateArrivals(
          {int? staffId, String? status, String? from, String? to, int page = 1}) =>
      _page('/reports/late-arrivals',
          page: page, query: _reportQuery(staffId, status, from, to));

  /// GET /reports/absences
  Future<PagedResult> reportAbsences(
          {int? staffId, String? status, String? from, String? to, int page = 1}) =>
      _page('/reports/absences',
          page: page, query: _reportQuery(staffId, status, from, to));

  /// GET /reports/overtime
  Future<PagedResult> reportOvertime(
          {int? staffId, String? status, String? from, String? to, int page = 1}) =>
      _page('/reports/overtime',
          page: page, query: _reportQuery(staffId, status, from, to));

  /// GET /reports/leave
  Future<PagedResult> reportLeave(
          {String? status, String? from, String? to, int page = 1}) =>
      _page('/reports/leave',
          page: page, query: {'status': status, 'from': from, 'to': to});

  /// GET /reports/headcount (HR/SA)
  Future<Json> reportHeadcount() async => _map(await _get('/reports/headcount'));

  /// POST /reports/exports — reportType: attendance | late-arrivals | absences |
  /// overtime | leave | headcount
  Future<Json> createExport(String reportType, {Json? filters}) async =>
      _map(await _post('/reports/exports', {
        'report_type': reportType,
        'format': 'csv',
        if (filters != null) 'filters': filters,
      }));

  /// GET /reports/exports/{id}
  Future<Json> getExport(int id) async => _map(await _get('/reports/exports/$id'));

  /// GET /reports/exports/{id}/download — saves the CSV to [savePath].
  Future<void> downloadExport(int id, String savePath) =>
      _download('/reports/exports/$id/download', savePath);

  // ═════════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS & NOTIFICATIONS
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /announcements (no total/last_page returned)
  Future<PagedResult> listAnnouncements({int page = 1}) =>
      _page('/announcements', page: page);

  /// GET /announcements/{id}
  Future<Json> getAnnouncement(int id) async =>
      _map(await _get('/announcements/$id'));

  /// POST /announcements (HR/SA) — audience: all | branch | department
  Future<Json> createAnnouncement({
    required String title,
    required String body,
    String? audience,
    Json? audienceMeta,
    String? expiresAt, // ISO-8601
    bool publish = false,
  }) async =>
      _map(await _post('/announcements', {
        'title': title,
        'body': body,
        'audience': audience,
        'audience_meta': audienceMeta,
        'expires_at': expiresAt,
        'publish': publish,
      }));

  /// PUT /announcements/{id} (author or admin)
  Future<Json> updateAnnouncement(int id, Json fields) async =>
      _map(await _put('/announcements/$id', fields));

  /// POST /announcements/{id}/publish (HR/SA)
  Future<Json> publishAnnouncement(int id) async =>
      _map(await _post('/announcements/$id/publish'));

  /// POST /announcements/{id}/read
  Future<void> markAnnouncementRead(int id) async =>
      _post('/announcements/$id/read');

  /// GET /notifications — PagedResult.extra['unread_count'] holds the badge number.
  Future<PagedResult> listNotifications({int page = 1}) =>
      _page('/notifications', page: page);

  /// POST /notifications/{id}/read
  Future<void> markNotificationRead(int id) async =>
      _post('/notifications/$id/read');

  /// POST /notifications/read-all
  Future<void> markAllNotificationsRead() async => _post('/notifications/read-all');

  /// GET /notification-preferences -> {push, email, in_app}
  Future<Json> notificationPreferences() async =>
      _map(await _get('/notification-preferences'));

  /// PUT /notification-preferences
  Future<Json> updateNotificationPreferences(
          {bool? push, bool? email, bool? inApp}) async =>
      _map(await _put('/notification-preferences', {
        if (push != null) 'push': push,
        if (email != null) 'email': email,
        if (inApp != null) 'in_app': inApp,
      }));

  // ═════════════════════════════════════════════════════════════════════════
  // DOCUMENTS
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /documents (raw paginator)
  Future<PagedResult> listDocuments({int page = 1}) => _page('/documents', page: page);

  /// POST /documents (multipart). visibility: private | staff | public
  Future<Json> uploadDocument({
    required String title,
    required String filePath, // pdf/doc/docx/xls/xlsx/jpg/jpeg/png/txt, max 10 MB
    String? filename,
    String? category,
    String? visibility,
    int? ownerStaffId,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'file': await _file(filePath, filename: filename),
      if (category != null) 'category': category,
      if (visibility != null) 'visibility': visibility,
      if (ownerStaffId != null) 'owner_staff_id': ownerStaffId,
    });
    return _map(await _post('/documents', form));
  }

  /// GET /documents/{id}
  Future<Json> getDocument(int id) async => _map(await _get('/documents/$id'));

  /// GET /documents/{id}/download — saves the file to [savePath].
  Future<void> downloadDocument(int id, String savePath) =>
      _download('/documents/$id/download', savePath);

  /// DELETE /documents/{id}
  Future<void> deleteDocument(int id) async => _delete('/documents/$id');

  Future<void> _download(String path, String savePath) async {
    try {
      await _dio.download(path, savePath);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EXPENSES
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /expense/categories
  Future<List<Json>> expenseCategories() async =>
      _list(await _get('/expense/categories'));

  /// GET /expenses (raw paginator)
  Future<PagedResult> listExpenses({String? status, int page = 1}) =>
      _page('/expenses', page: page, query: {'status': status});

  /// POST /expenses (multipart, optional receipt). submit=false saves a draft.
  Future<Json> createExpense({
    required int categoryId,
    required num amount,
    required String expenseDate, // yyyy-MM-dd, not in the future
    String? currency, // 3 letters, server default INR
    String? description,
    String? receiptPath, // pdf/jpg/png, max 5 MB
    bool submit = false,
  }) async {
    final form = FormData.fromMap({
      'category_id': categoryId,
      'amount': amount,
      'expense_date': expenseDate,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (receiptPath != null) 'receipt': await _file(receiptPath),
      'submit': _b(submit),
    });
    return _map(await _post('/expenses', form));
  }

  /// GET /expenses/{id}
  Future<Json> getExpense(int id) async => _map(await _get('/expenses/$id'));

  /// PATCH /expenses/{id} (owner; draft/rejected only)
  Future<Json> updateExpense(int id, Json fields) async =>
      _map(await _patch('/expenses/$id', fields));

  /// POST /expenses/{id}/submit
  Future<Json> submitExpense(int id) async =>
      _map(await _post('/expenses/$id/submit'));

  /// POST /expenses/{id}/approve (Manager/HR/SA)
  Future<Json> approveExpense(int id, {String? comments}) async =>
      _map(await _post('/expenses/$id/approve',
          {if (comments != null) 'comments': comments}));

  /// POST /expenses/{id}/reject (Manager/HR/SA) — comments required
  Future<Json> rejectExpense(int id, {required String comments}) async =>
      _map(await _post('/expenses/$id/reject', {'comments': comments}));

  /// POST /expenses/{id}/mark-paid (HR/SA)
  Future<Json> markExpensePaid(int id, {String? paymentReference}) async =>
      _map(await _post('/expenses/$id/mark-paid',
          {if (paymentReference != null) 'payment_reference': paymentReference}));

  // ═════════════════════════════════════════════════════════════════════════
  // MEETINGS
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /meeting-rooms
  Future<List<Json>> meetingRooms({int? branchId}) async =>
      _list(await _get('/meeting-rooms', query: {'branch_id': branchId}));

  /// GET /meetings (raw paginator). [all] only works for admins.
  Future<PagedResult> listMeetings({bool all = false, int page = 1}) =>
      _page('/meetings', page: page, query: {if (all) 'all': 1});

  /// POST /meetings — send times as ISO-8601 (UTC recommended)
  Future<Json> createMeeting({
    required String title,
    required String startsAt,
    required String endsAt,
    int? roomId,
    String? meetingUrl,
    List<int>? participantStaffIds,
  }) async =>
      _map(await _post('/meetings', {
        'title': title,
        'starts_at': startsAt,
        'ends_at': endsAt,
        'room_id': roomId,
        'meeting_url': meetingUrl,
        'participant_ids': participantStaffIds,
      }));

  /// GET /meetings/{id}
  Future<Json> getMeeting(int id) async => _map(await _get('/meetings/$id'));

  /// PATCH /meetings/{id} (organiser/admin)
  Future<Json> updateMeeting(int id, Json fields) async =>
      _map(await _patch('/meetings/$id', fields));

  /// POST /meetings/{id}/cancel (organiser/admin)
  Future<void> cancelMeeting(int id) async => _post('/meetings/$id/cancel');

  /// POST /meetings/{id}/response — accepted | declined | tentative
  Future<Json> respondToMeeting(int id, String response) async =>
      _map(await _post('/meetings/$id/response', {'response': response}));

  // ═════════════════════════════════════════════════════════════════════════
  // ASSETS (HR/SA)
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /assets (raw paginator)
  Future<PagedResult> listAssets({String? status, int page = 1}) =>
      _page('/assets', page: page, query: {'status': status});

  /// POST /assets
  Future<Json> createAsset({
    required String assetTag,
    required String name,
    String? category,
    String? serialNumber,
  }) async =>
      _map(await _post('/assets', {
        'asset_tag': assetTag,
        'name': name,
        'category': category,
        'serial_number': serialNumber,
      }));

  /// GET /assets/{id}
  Future<Json> getAsset(int id) async => _map(await _get('/assets/$id'));

  /// PATCH /assets/{id} — status: available | assigned | maintenance | retired
  Future<Json> updateAsset(int id, Json fields) async =>
      _map(await _patch('/assets/$id', fields));

  /// POST /assets/{id}/assign
  Future<Json> assignAsset(int id,
          {required int staffId, String? conditionNotes}) async =>
      _map(await _post('/assets/$id/assign',
          {'staff_id': staffId, 'condition_notes': conditionNotes}));

  /// POST /assets/{id}/return
  Future<Json> returnAsset(int id, {String? conditionNotes}) async =>
      _map(await _post('/assets/$id/return',
          {if (conditionNotes != null) 'condition_notes': conditionNotes}));

  // ═════════════════════════════════════════════════════════════════════════
  // HELPDESK
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /ticket-categories
  Future<List<Json>> ticketCategories() async =>
      _list(await _get('/ticket-categories'));

  /// GET /tickets (no total/last_page returned)
  Future<PagedResult> listTickets({
    String? status,
    String? priority,
    int? categoryId,
    int page = 1,
  }) =>
      _page('/tickets', page: page, query: {
        'status': status,
        'priority': priority,
        'category_id': categoryId,
      });

  /// POST /tickets — priority: low | medium | high | urgent
  Future<Json> createTicket({
    required String subject,
    required String description,
    int? categoryId,
    String? priority,
  }) async =>
      _map(await _post('/tickets', {
        'subject': subject,
        'description': description,
        'category_id': categoryId,
        'priority': priority,
      }));

  /// GET /tickets/{id}
  Future<Json> getTicket(int id) async => _map(await _get('/tickets/$id'));

  /// POST /tickets/{id}/comments
  Future<Json> commentOnTicket(int id, String comment) async =>
      _map(await _post('/tickets/$id/comments', {'comment': comment}));

  /// POST /tickets/{id}/assign (HR/SA) — assignedTo is a USER id
  Future<Json> assignTicket(int id, {required int assignedToUserId}) async =>
      _map(await _post('/tickets/$id/assign', {'assigned_to': assignedToUserId}));

  /// POST /tickets/{id}/status (HR/SA) — assigned | in_progress |
  /// waiting_for_employee | resolved
  Future<Json> changeTicketStatus(int id, String status, {String? reason}) async =>
      _map(await _post('/tickets/$id/status',
          {'status': status, if (reason != null) 'reason': reason}));

  /// POST /tickets/{id}/close
  Future<Json> closeTicket(int id, {String? reason}) async =>
      _map(await _post('/tickets/$id/close', {if (reason != null) 'reason': reason}));

  // ═════════════════════════════════════════════════════════════════════════
  // ADMIN (Super Admin)
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /admin/users (raw paginator)
  Future<PagedResult> adminUsers({String? search, int page = 1}) =>
      _page('/admin/users', page: page, query: {'search': search});

  /// POST /admin/users/{id}/roles — replaces the user's roles
  Future<Json> assignRoles(int userId, List<String> roles) async =>
      _map(await _post('/admin/users/$userId/roles', {'roles': roles}));

  /// GET /admin/roles
  Future<List<Json>> adminRoles() async => _list(await _get('/admin/roles'));

  /// POST /admin/roles
  Future<Json> createRole(String name, {List<String>? permissions}) async =>
      _map(await _post('/admin/roles', {'name': name, 'permissions': permissions}));

  /// PUT /admin/roles/{id} — permissions replace the existing set
  Future<Json> updateRole(int id, {String? name, List<String>? permissions}) async =>
      _map(await _put('/admin/roles/$id', {
        if (name != null) 'name': name,
        if (permissions != null) 'permissions': permissions,
      }));

  /// GET /admin/settings -> {key: value}
  Future<Json> adminSettings() async => _map(await _get('/admin/settings'));

  /// PUT /admin/settings — [settings] is a flat key/value map
  Future<Json> updateAdminSettings(Map<String, dynamic> settings) async =>
      _map(await _put('/admin/settings', {
        'settings': settings.entries
            .map((e) => {'key': e.key, 'value': e.value})
            .toList(),
      }));

  /// GET /admin/audit-logs (raw paginator, 50/page)
  Future<PagedResult> auditLogs({
    String? action,
    String? subjectType,
    int? actorUserId,
    String? from,
    String? to,
    int page = 1,
  }) =>
      _page('/admin/audit-logs', page: page, query: {
        'action': action,
        'subject_type': subjectType,
        'actor_user_id': actorUserId,
        'from': from,
        'to': to,
      });
}
