import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../models/enums.dart';
import '../features/admin/add_employee_screen.dart';
import '../features/admin/admin_attendance_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_settings_screen.dart';
import '../features/admin/announcements_admin_screen.dart';
import '../features/admin/assets_admin_screen.dart';
import '../features/admin/audit_screen.dart';
import '../features/admin/branches_screen.dart';
import '../features/admin/departments_screen.dart';
import '../features/admin/documents_admin_screen.dart';
import '../features/admin/employees_screen.dart';
import '../features/admin/expenses_admin_screen.dart';
import '../features/admin/holidays_screen.dart';
import '../features/admin/requests_admin_screens.dart';
import '../features/admin/shifts_screen.dart';
import '../features/admin/reports_screen.dart';
import '../features/announcements/announcements_screen.dart';
import '../features/assets/assets_screen.dart';
import '../features/attendance/attendance_details_screen.dart';
import '../features/attendance/attendance_history_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/attendance/qr_attendance_screen.dart';
import '../features/attendance/regularization_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/calendar/company_calendar_screen.dart';
import '../features/dashboard/employee_home_screen.dart';
import '../features/directory/directory_screen.dart';
import '../features/documents/documents_screen.dart';
import '../features/employees/employee_detail_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/helpdesk/helpdesk_screen.dart';
import '../features/leave/apply_leave_screen.dart';
import '../features/leave/leave_screen.dart';
import '../features/manager/approval_center_screen.dart';
import '../features/manager/manager_dashboard_screen.dart';
import '../features/manager/my_team_screen.dart';
import '../features/manager/team_attendance_screen.dart';
import '../features/manager/team_reports_screen.dart';
import '../features/meetings/meetings_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/payslips/payslips_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/help_support_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/work_from_home/apply_wfh_screen.dart';
import '../features/work_from_home/wfh_screen.dart';
import 'role_shell.dart';

Page<void> _page(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondary, child) => FadeTransition(opacity: animation, child: child),
    );

GoRoute _r(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, pageBuilder: (context, state) => _page(state, build(state)));

GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/auth/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final role = auth.role;
      final inAuth = path.startsWith('/auth');
      if (role == null) return inAuth ? null : '/auth/login';
      if (inAuth) return role.homePath;
      if (!path.startsWith(role.basePath)) return role.homePath;
      return null;
    },
    routes: [
      _r('/auth/splash', (s) => const SplashScreen()),
      _r('/auth/onboarding', (s) => const OnboardingScreen()),
      _r('/auth/login', (s) => const LoginScreen()),
      _r('/auth/forgot-password', (s) => const ForgotPasswordScreen()),

      // ------------------------------------------------------------ employee
      ShellRoute(
        builder: (context, state, child) => RoleShell(role: UserRole.employee, location: state.uri.path, child: child),
        routes: [
          _r('/employee/home', (s) => const EmployeeHomeScreen()),
          _r('/employee/attendance', (s) => const AttendanceScreen()),
          _r('/employee/attendance/history', (s) => const AttendanceHistoryScreen()),
          _r('/employee/attendance/details', (s) => AttendanceDetailsScreen(id: s.uri.queryParameters['id'] ?? '')),
          _r('/employee/attendance/regularization', (s) => RegularizationScreen(initialDate: s.uri.queryParameters['date'])),
          _r('/employee/attendance/qr', (s) => const QrAttendanceScreen()),
          _r('/employee/leave', (s) => const LeaveScreen()),
          _r('/employee/leave/apply', (s) => const ApplyLeaveScreen()),
          _r('/employee/wfh', (s) => const WfhScreen()),
          _r('/employee/wfh/apply', (s) => const ApplyWfhScreen()),
          _r('/employee/announcements', (s) => const AnnouncementsScreen()),
          _r('/employee/notifications', (s) => const NotificationsScreen()),
          _r('/employee/calendar', (s) => const CompanyCalendarScreen()),
          _r('/employee/directory', (s) => const DirectoryScreen()),
          _r('/employee/directory/:id', (s) => EmployeeDetailScreen(id: s.pathParameters['id'] ?? '')),
          _r('/employee/profile', (s) => const ProfileScreen()),
          _r('/employee/documents', (s) => const DocumentsScreen()),
          _r('/employee/payslips', (s) => const PayslipsScreen()),
          _r('/employee/expenses', (s) => const ExpensesScreen()),
          _r('/employee/meetings', (s) => const MeetingsScreen()),
          _r('/employee/assets', (s) => const AssetsScreen()),
          _r('/employee/helpdesk', (s) => const HelpdeskScreen()),
          _r('/employee/settings', (s) => const SettingsScreen()),
          _r('/employee/help', (s) => const HelpSupportScreen()),
        ],
      ),

      // ------------------------------------------------------------- manager
      ShellRoute(
        builder: (context, state, child) => RoleShell(role: UserRole.manager, location: state.uri.path, child: child),
        routes: [
          _r('/manager/home', (s) => const ManagerDashboardScreen()),
          _r('/manager/team', (s) => const MyTeamScreen()),
          _r('/manager/team/:id', (s) => EmployeeDetailScreen(id: s.pathParameters['id'] ?? '')),
          _r('/manager/attendance', (s) => const TeamAttendanceScreen()),
          _r('/manager/approvals', (s) => const ApprovalCenterScreen()),
          _r('/manager/reports', (s) => const TeamReportsScreen()),
          _r('/manager/notifications', (s) => const NotificationsScreen()),
          _r('/manager/settings', (s) => const SettingsScreen()),
        ],
      ),

      // --------------------------------------------------------------- admin
      ShellRoute(
        builder: (context, state, child) => RoleShell(role: UserRole.hr, location: state.uri.path, child: child),
        routes: [
          _r('/admin/home', (s) => const AdminDashboardScreen()),
          _r('/admin/employees', (s) => const EmployeesScreen()),
          _r('/admin/employees/add', (s) => const AddEmployeeScreen()),
          _r('/admin/employees/:id', (s) => EmployeeDetailScreen(id: s.pathParameters['id'] ?? '')),
          _r('/admin/departments', (s) => const DepartmentsScreen()),
          _r('/admin/branches', (s) => const BranchesScreen()),
          _r('/admin/shifts', (s) => const ShiftsScreen()),
          _r('/admin/holidays', (s) => const HolidaysScreen()),
          _r('/admin/attendance', (s) => const AdminAttendanceScreen()),
          _r('/admin/leaves', (s) => const AdminLeavesScreen()),
          _r('/admin/wfh', (s) => const AdminWfhScreen()),
          _r('/admin/announcements', (s) => const AdminAnnouncementsScreen()),
          _r('/admin/documents', (s) => const AdminDocumentsScreen()),
          _r('/admin/expenses', (s) => const AdminExpensesScreen()),
          _r('/admin/assets', (s) => const AdminAssetsScreen()),
          _r('/admin/reports', (s) => const AdminReportsScreen()),
          _r('/admin/audit', (s) => const AuditLogsScreen()),
          _r('/admin/settings', (s) => const AdminSettingsScreen()),
        ],
      ),
    ],
  );
}
