import '../mock_data/mock_data.dart';
import '../models/models.dart';
import 'app_repository.dart';

/// First-demo implementation backed by generated static data.
class MockAppRepository implements AppRepository {
  @override
  String userIdFor(UserRole role) => switch (role) {
        UserRole.employee => MockData.employeeId,
        UserRole.manager => MockData.managerId,
        UserRole.hr => MockData.hrId,
      };

  @override
  List<String> get leaveTypeNames => const ['Casual Leave', 'Sick Leave', 'Earned Leave', 'Comp Off'];

  @override
  List<String> get expenseCategoryNames =>
      const ['Travel', 'Meals', 'Equipment', 'Training', 'Software', 'Office'];

  @override
  List<String> get ticketCategoryNames => const ['IT Support', 'HR Query', 'Facilities', 'Payroll', 'Other'];

  @override
  Future<AppSnapshot> load() async {
    // Simulated network latency so shimmer loaders are visible.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return MockData.build();
  }

  @override
  Future<void> saveEmployee(Employee employee, {bool isNew = false}) async {}

  @override
  Future<void> saveAttendance(Attendance attendance) async {}

  @override
  Future<void> saveLeave(LeaveRequest request) async {}

  @override
  Future<void> saveWfh(WFHRequest request) async {}

  @override
  Future<void> saveRegularization(RegularizationRequest request) async {}

  @override
  Future<void> saveDepartment(Department department, {bool isNew = false}) async {}

  @override
  Future<void> saveBranch(Branch branch, {bool isNew = false}) async {}

  @override
  Future<void> saveShift(Shift shift, {bool isNew = false}) async {}

  @override
  Future<void> saveHoliday(Holiday holiday) async {}

  @override
  Future<void> deleteHoliday(Holiday holiday) async {}

  @override
  Future<void> saveAnnouncement(Announcement announcement, {bool isNew = false}) async {}

  @override
  Future<void> publishAnnouncement(Announcement announcement) async {}

  @override
  Future<void> markNotificationRead(AppNotification notification) async {}

  @override
  Future<void> markAllNotificationsRead() async {}

  @override
  Future<void> deleteDocument(DocumentItem document) async {}

  @override
  Future<void> saveExpense(Expense expense, {bool isNew = false}) async {}

  @override
  Future<void> saveAsset(Asset asset, {bool isNew = false}) async {}

  @override
  Future<void> assignAsset(Asset asset, String? employeeId) async {}

  @override
  Future<void> saveTicket(Ticket ticket, {bool isNew = false}) async {}

  @override
  Future<void> replyTicket(Ticket ticket, String text) async {}
}
