import '../models/models.dart';

/// Everything the app needs, loaded in one go.
class AppSnapshot {
  AppSnapshot({
    required this.employees,
    required this.departments,
    required this.branches,
    required this.shifts,
    required this.holidays,
    required this.attendance,
    required this.leaves,
    required this.wfhRequests,
    required this.regularizations,
    required this.announcements,
    required this.notifications,
    required this.documents,
    required this.payslips,
    required this.expenses,
    required this.meetings,
    required this.assets,
    required this.tickets,
    required this.auditLogs,
    this.leaveTypeNames = const [],
    this.leaveBalances = const [],
  });

  final List<Employee> employees;
  final List<Department> departments;
  final List<Branch> branches;
  final List<Shift> shifts;
  final List<Holiday> holidays;
  final List<Attendance> attendance;
  final List<LeaveRequest> leaves;
  final List<WFHRequest> wfhRequests;
  final List<RegularizationRequest> regularizations;
  final List<Announcement> announcements;
  final List<AppNotification> notifications;
  final List<DocumentItem> documents;
  final List<Payslip> payslips;
  final List<Expense> expenses;
  final List<Meeting> meetings;
  final List<Asset> assets;
  final List<Ticket> tickets;
  final List<AuditLog> auditLogs;

  /// Leave types offered by the backend (`/leave/types`), by display name.
  /// Empty in mock mode — the controller falls back to its demo quota.
  final List<String> leaveTypeNames;

  /// Server-computed leave balances for the signed-in employee
  /// (`/leave/balances`). Empty in mock mode.
  final List<LeaveBalance> leaveBalances;
}

/// Repository contract.
///
/// The UI never talks to mock lists directly. Controllers depend on this
/// interface, so the [MockAppRepository] can later be swapped for an
/// `ApiAppRepository` (Dio + REST) without touching any screen.
abstract class AppRepository {
  /// Employee id for the signed-in user (mock: per-role demo id; API: staff id).
  String userIdFor(UserRole role);

  /// Extra option lists used by dropdowns. Mock returns demo values; the API
  /// repository caches `/leave/types`, `/expense/categories` and
  /// `/ticket-categories` from the last [load].
  List<String> get leaveTypeNames;
  List<String> get expenseCategoryNames;
  List<String> get ticketCategoryNames;

  Future<AppSnapshot> load();

  // Write-side hooks. The mock implementation is a no-op because the
  // controller keeps local state; an API implementation would POST/PUT here.
  // `isNew` distinguishes create calls from updates on local-only items.
  Future<void> saveEmployee(Employee employee, {bool isNew});
  Future<void> saveAttendance(Attendance attendance);
  Future<void> saveLeave(LeaveRequest request);
  Future<void> saveWfh(WFHRequest request);
  Future<void> saveRegularization(RegularizationRequest request);

  // Organisation setup (HR/SA only).
  Future<void> saveDepartment(Department department, {bool isNew});
  Future<void> saveBranch(Branch branch, {bool isNew});
  Future<void> saveShift(Shift shift, {bool isNew});
  Future<void> saveHoliday(Holiday holiday);
  Future<void> deleteHoliday(Holiday holiday);

  // Announcements & notifications.
  Future<void> saveAnnouncement(Announcement announcement, {bool isNew});
  Future<void> publishAnnouncement(Announcement announcement);
  Future<void> markNotificationRead(AppNotification notification);
  Future<void> markAllNotificationsRead();

  // Documents, expenses, assets, helpdesk.
  Future<void> deleteDocument(DocumentItem document);
  Future<void> saveExpense(Expense expense, {bool isNew});
  Future<void> saveAsset(Asset asset, {bool isNew});
  Future<void> assignAsset(Asset asset, String? employeeId);
  Future<void> saveTicket(Ticket ticket, {bool isNew});
  Future<void> replyTicket(Ticket ticket, String text);
}
