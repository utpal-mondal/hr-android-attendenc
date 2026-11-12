import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/status_ext.dart';
import 'app_button.dart';
import 'app_card.dart';

StatusBadge attendanceBadge(AttendanceStatus s) => StatusBadge(label: s.label, color: s.color);
StatusBadge requestBadge(RequestStatus s) => StatusBadge(label: s.label, color: s.color);

Color categoryColor(String c) => switch (c) {
      'Policy' => AppColors.info,
      'Event' => AppColors.purple,
      'Holiday' => AppColors.teal,
      'HR' => AppColors.orange,
      'News' => AppColors.navy,
      _ => AppColors.textSecondary,
    };

IconData categoryIcon(String c) => switch (c) {
      'Policy' => Icons.policy_outlined,
      'Event' => Icons.event_available_outlined,
      'Holiday' => Icons.celebration_outlined,
      'HR' => Icons.groups_2_outlined,
      'News' => Icons.newspaper_outlined,
      _ => Icons.campaign_outlined,
    };

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({super.key, required this.record, this.onTap, this.employeeName});
  final Attendance record;
  final VoidCallback? onTap;
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    final a = record;
    final s = a.status;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: s.color.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('${a.date.day}', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: s.color)),
                Text(Fmt.weekday(a.date), style: TextStyle(fontSize: 11.5, color: s.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employeeName != null) Text(employeeName!, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (a.hasWorkData)
                  Text('${Fmt.time(a.checkIn)}  -  ${a.checkOut == null ? 'Working' : Fmt.time(a.checkOut)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))
                else
                  Text(a.note ?? (s == AttendanceStatus.holiday ? 'Public holiday' : s.label), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    if (a.hasWorkData) IconText(Icons.timer_outlined, Fmt.duration(a.worked)),
                    if (a.overtime > Duration.zero && a.checkOut != null) IconText(Icons.bolt, 'OT ${Fmt.duration(a.overtime)}', color: AppColors.info),
                    IconText(Icons.location_on_outlined, a.office),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          attendanceBadge(s),
        ],
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  const EmployeeCard({super.key, required this.employee, this.onTap, this.badge, this.subtitleOverride});
  final Employee employee;
  final VoidCallback? onTap;
  final Widget? badge;
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    final e = employee;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AvatarWidget(name: e.name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text(subtitleOverride ?? e.designation, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  Flexible(child: IconText(Icons.business_outlined, '${e.department} - ${e.branch.split(' ').first}')),
                ]),
              ],
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          if (!e.active) ...[const SizedBox(width: 8), StatusBadge(label: 'Inactive', color: AppColors.textSecondary)],
        ],
      ),
    );
  }
}

class LeaveCard extends StatelessWidget {
  const LeaveCard({super.key, required this.request});
  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final l = request;
    final range = sameDay(l.from, l.to) ? Fmt.date(l.from) : '${Fmt.dateShort(l.from)} - ${Fmt.date(l.to)}';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.purple.withValues(alpha:0.10), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.beach_access_outlined, color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.type, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('$range  -  ${l.days % 1 == 0 ? l.days.toInt() : l.days} day(s)${l.halfDay ? ' (half day)' : ''}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              requestBadge(l.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(l.reason, style: const TextStyle(fontSize: 13.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 14, children: [
            IconText(Icons.schedule, 'Applied ${Fmt.dateShort(l.appliedOn)}'),
            if (l.hasAttachment) const IconText(Icons.attach_file, 'Attachment'),
          ]),
          if (l.reviewerNote != null && l.status == RequestStatus.rejected) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha:0.06), borderRadius: BorderRadius.circular(8)),
              child: Text('Manager note: ${l.reviewerNote}', style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
            ),
          ],
        ],
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement, this.onTap, this.trailing, this.compact = false});
  final Announcement announcement;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final color = categoryColor(a.category);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(categoryIcon(a.category), color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(label: a.category, color: color),
                    if (a.pinned) const IconText(Icons.push_pin_outlined, 'Pinned'),
                    if (!a.published) const StatusBadge(label: 'Draft', color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 6),
                Text(a.title, maxLines: compact ? 2 : 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(a.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 6),
                Text('${a.author}  -  ${Fmt.date(a.date)}  -  ${a.audience}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ApprovalCard extends StatelessWidget {
  const ApprovalCard({super.key, required this.item, required this.employeeName, this.onApprove, this.onReject});
  final ApprovalItem item;
  final String employeeName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final showActions = item.status == RequestStatus.pending && onApprove != null;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: employeeName, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employeeName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${item.kind.label}  -  applied ${Fmt.dateShort(item.appliedOn)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              requestBadge(item.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(item.kind.icon, size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 4),
                Text(item.detail, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(item.reason, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppButton(label: 'Reject', icon: Icons.close, type: AppButtonType.secondary, compact: true, onPressed: onReject)),
                const SizedBox(width: 10),
                Expanded(child: AppButton(label: 'Approve', icon: Icons.check, compact: true, onPressed: onApprove)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.document, this.onView, this.onDownload, this.onDelete});
  final DocumentItem document;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final d = document;
    final color = switch (d.extension) {
      'PDF' => AppColors.danger,
      'DOCX' => AppColors.info,
      _ => AppColors.purple,
    };
    return AppCard(
      onTap: onView,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha:0.10), borderRadius: BorderRadius.circular(10)),
            child: Text(d.extension, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text('${d.category}  -  ${d.size}  -  ${Fmt.date(d.updated)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onDownload != null) IconButton(icon: const Icon(Icons.file_download_outlined), tooltip: 'Download', onPressed: onDownload),
          if (onDelete != null) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), tooltip: 'Delete', onPressed: onDelete),
        ],
      ),
    );
  }
}

Color expenseColor(String status) => switch (status) {
      'Approved' => AppColors.success,
      'Reimbursed' => AppColors.teal,
      'Rejected' => AppColors.danger,
      _ => AppColors.warning,
    };

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense, this.employeeName, this.onApprove, this.onReject, this.onTap});
  final Expense expense;
  final String? employeeName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final showActions = e.status == 'Pending' && onApprove != null;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.orange.withValues(alpha:0.10), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.orange, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${employeeName != null ? '$employeeName  -  ' : ''}${e.category}  -  ${Fmt.date(e.date)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.money(e.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  StatusBadge(label: e.status, color: expenseColor(e.status)),
                ],
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppButton(label: 'Reject', icon: Icons.close, type: AppButtonType.secondary, compact: true, onPressed: onReject)),
                const SizedBox(width: 10),
                Expanded(child: AppButton(label: 'Approve', icon: Icons.check, compact: true, onPressed: onApprove)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
