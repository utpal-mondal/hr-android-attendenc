import 'package:flutter/material.dart';

import '../models/enums.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.path, {this.primary = false});
  final String label;
  final IconData icon;
  final String path;

  /// Shown in the mobile bottom bar (others go under "More").
  final bool primary;
}

class NavConfig {
  static List<NavItem> forRole(UserRole role) => switch (role) {
        UserRole.employee => const [
            NavItem('Home', Icons.home_outlined, '/employee/home', primary: true),
            NavItem('Attendance', Icons.fingerprint, '/employee/attendance', primary: true),
            NavItem('Leave', Icons.beach_access_outlined, '/employee/leave', primary: true),
            NavItem('Directory', Icons.groups_outlined, '/employee/directory', primary: true),
            NavItem('Work From Home', Icons.home_work_outlined, '/employee/wfh'),
            NavItem('Calendar', Icons.calendar_month_outlined, '/employee/calendar'),
            NavItem('Announcements', Icons.campaign_outlined, '/employee/announcements'),
            NavItem('Notifications', Icons.notifications_none, '/employee/notifications'),
            NavItem('Documents', Icons.folder_outlined, '/employee/documents'),
            NavItem('Payslips', Icons.payments_outlined, '/employee/payslips'),
            NavItem('Expenses', Icons.receipt_long_outlined, '/employee/expenses'),
            NavItem('Meetings', Icons.videocam_outlined, '/employee/meetings'),
            NavItem('Assets', Icons.laptop_mac, '/employee/assets'),
            NavItem('Helpdesk', Icons.support_agent, '/employee/helpdesk'),
            NavItem('My Profile', Icons.person_outline, '/employee/profile'),
            NavItem('Settings', Icons.settings_outlined, '/employee/settings'),
            NavItem('Help & Support', Icons.help_outline, '/employee/help'),
          ],
        UserRole.manager => const [
            NavItem('Dashboard', Icons.dashboard_outlined, '/manager/home', primary: true),
            NavItem('My Team', Icons.groups_outlined, '/manager/team', primary: true),
            NavItem('Attendance', Icons.fingerprint, '/manager/attendance', primary: true),
            NavItem('Approvals', Icons.approval, '/manager/approvals', primary: true),
            NavItem('Reports', Icons.bar_chart_rounded, '/manager/reports'),
            NavItem('Notifications', Icons.notifications_none, '/manager/notifications'),
            NavItem('Settings', Icons.settings_outlined, '/manager/settings'),
          ],
        UserRole.hr => const [
            NavItem('Dashboard', Icons.dashboard_outlined, '/admin/home', primary: true),
            NavItem('Employees', Icons.badge_outlined, '/admin/employees', primary: true),
            NavItem('Attendance', Icons.fingerprint, '/admin/attendance', primary: true),
            NavItem('Leave', Icons.beach_access_outlined, '/admin/leaves', primary: true),
            NavItem('WFH', Icons.home_work_outlined, '/admin/wfh'),
            NavItem('Departments', Icons.account_tree_outlined, '/admin/departments'),
            NavItem('Branches', Icons.apartment, '/admin/branches'),
            NavItem('Shifts', Icons.schedule, '/admin/shifts'),
            NavItem('Holidays', Icons.celebration_outlined, '/admin/holidays'),
            NavItem('Announcements', Icons.campaign_outlined, '/admin/announcements'),
            NavItem('Documents', Icons.folder_outlined, '/admin/documents'),
            NavItem('Expenses', Icons.receipt_long_outlined, '/admin/expenses'),
            NavItem('Assets', Icons.inventory_2_outlined, '/admin/assets'),
            NavItem('Reports', Icons.bar_chart_rounded, '/admin/reports'),
            NavItem('Audit Logs', Icons.history, '/admin/audit'),
            NavItem('Settings', Icons.settings_outlined, '/admin/settings'),
          ],
      };
}
