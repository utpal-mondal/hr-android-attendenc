import 'enums.dart';

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.from,
    required this.to,
    this.halfDay = false,
    required this.reason,
    this.status = RequestStatus.pending,
    required this.appliedOn,
    this.hasAttachment = false,
    this.reviewerNote,
  });

  final String id;
  final String employeeId;
  final String type;
  final DateTime from;
  final DateTime to;
  final bool halfDay;
  final String reason;
  RequestStatus status;
  final DateTime appliedOn;
  final bool hasAttachment;
  String? reviewerNote;

  /// Working days between [from] and [to] (weekends excluded).
  double get days {
    if (halfDay) return 0.5;
    var count = 0;
    var d = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!d.isAfter(end)) {
      if (d.weekday < 6) count++;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return count == 0 ? 1 : count.toDouble();
  }
}

class LeaveBalance {
  LeaveBalance({required this.type, required this.total, required this.used, required this.pending});
  final String type;
  final double total;
  final double used;
  final double pending;
  double get remaining => total - used - pending;
}

class WFHRequest {
  WFHRequest({
    required this.id,
    required this.employeeId,
    required this.from,
    required this.to,
    required this.reason,
    this.status = RequestStatus.pending,
    required this.appliedOn,
  });

  final String id;
  final String employeeId;
  final DateTime from;
  final DateTime to;
  final String reason;
  RequestStatus status;
  final DateTime appliedOn;

  int get days {
    var count = 0;
    var d = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!d.isAfter(end)) {
      if (d.weekday < 6) count++;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return count == 0 ? 1 : count;
  }
}

class RegularizationRequest {
  RegularizationRequest({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.requestedIn,
    required this.requestedOut,
    required this.reason,
    this.status = RequestStatus.pending,
    required this.appliedOn,
    this.hasAttachment = false,
  });

  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime requestedIn;
  final DateTime requestedOut;
  final String reason;
  RequestStatus status;
  final DateTime appliedOn;
  final bool hasAttachment;
}

/// Unified view over leave / WFH / regularization requests for approval screens.
class ApprovalItem {
  ApprovalItem({
    required this.id,
    required this.kind,
    required this.employeeId,
    required this.title,
    required this.detail,
    required this.reason,
    required this.status,
    required this.appliedOn,
  });

  final String id;
  final ApprovalKind kind;
  final String employeeId;
  final String title;
  final String detail;
  final String reason;
  final RequestStatus status;
  final DateTime appliedOn;
}
