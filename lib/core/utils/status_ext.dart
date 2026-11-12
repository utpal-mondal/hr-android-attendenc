import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../theme/app_colors.dart';

extension AttendanceStatusUi on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.wfh => 'WFH',
        AttendanceStatus.leave => 'On Leave',
        AttendanceStatus.halfDay => 'Half Day',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.holiday => 'Holiday',
      };

  Color get color => switch (this) {
        AttendanceStatus.present => AppColors.success,
        AttendanceStatus.late => AppColors.warning,
        AttendanceStatus.wfh => AppColors.info,
        AttendanceStatus.leave => AppColors.purple,
        AttendanceStatus.halfDay => AppColors.orange,
        AttendanceStatus.absent => AppColors.danger,
        AttendanceStatus.holiday => AppColors.teal,
      };
}

extension RequestStatusUi on RequestStatus {
  String get label => switch (this) {
        RequestStatus.pending => 'Pending',
        RequestStatus.approved => 'Approved',
        RequestStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        RequestStatus.pending => AppColors.warning,
        RequestStatus.approved => AppColors.success,
        RequestStatus.rejected => AppColors.danger,
      };
}

extension ApprovalKindUi on ApprovalKind {
  String get label => switch (this) {
        ApprovalKind.leave => 'Leave',
        ApprovalKind.wfh => 'WFH',
        ApprovalKind.regularization => 'Regularization',
      };

  IconData get icon => switch (this) {
        ApprovalKind.leave => Icons.beach_access_outlined,
        ApprovalKind.wfh => Icons.home_work_outlined,
        ApprovalKind.regularization => Icons.edit_calendar_outlined,
      };
}
