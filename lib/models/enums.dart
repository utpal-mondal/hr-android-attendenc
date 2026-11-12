enum UserRole { employee, manager, hr }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.employee => 'Employee',
        UserRole.manager => 'Manager',
        UserRole.hr => 'HR / Admin',
      };
  String get basePath => switch (this) {
        UserRole.employee => '/employee',
        UserRole.manager => '/manager',
        UserRole.hr => '/admin',
      };
  String get homePath => '$basePath/home';
  String get demoEmail => switch (this) {
        UserRole.employee => 'employee@demo.com',
        UserRole.manager => 'manager@demo.com',
        UserRole.hr => 'hr@demo.com',
      };
}

enum AttendanceStatus { present, late, wfh, leave, halfDay, absent, holiday }

enum RequestStatus { pending, approved, rejected }

enum WorkState { notStarted, working, onBreak, completed }

enum AttendanceEventType { checkIn, breakStart, breakEnd, checkOut }

enum ApprovalKind { leave, wfh, regularization }
