import 'package:office_management/core/common.dart';

/// Approval queue for leave / WFH / regularization requests.
class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key, this.ids, this.kinds, this.allowActions = true});
  final Set<String>? ids;
  final Set<ApprovalKind>? kinds;
  final bool allowActions;

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> {
  RequestStatus? _status = RequestStatus.pending;
  ApprovalKind? _kind;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final all = app.approvals(employeeIds: widget.ids, kinds: widget.kinds);
    int count(RequestStatus s) => all.where((a) => a.status == s).length;
    final items = all.where((a) => (_status == null || a.status == _status) && (_kind == null || a.kind == _kind)).toList();
    final kindOptions = <ApprovalKind?>[null, ...(widget.kinds ?? ApprovalKind.values.toSet())];

    Future<void> act(ApprovalItem item, RequestStatus s) async {
      if (s == RequestStatus.rejected) {
        final ok = await showConfirmDialog(context,
            title: 'Reject request?', message: '${app.nameOf(item.employeeId)} will be notified that the request was rejected.', confirmLabel: 'Reject', destructive: true);
        if (!ok) return;
      }
      await app.reviewApproval(item, s);
      if (mounted) showAppSnack(this.context, s == RequestStatus.approved ? 'Request approved.' : 'Request rejected.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFilterChips<RequestStatus?>(
          options: const [RequestStatus.pending, RequestStatus.approved, RequestStatus.rejected, null],
          selected: _status,
          labelOf: (s) => s == null ? 'All (${all.length})' : '${s.label} (${count(s)})',
          onSelected: (s) => setState(() => _status = s),
        ),
        if (kindOptions.length > 2) ...[
          const Gap(10),
          AppFilterChips<ApprovalKind?>(options: kindOptions, selected: _kind, labelOf: (k) => k == null ? 'All types' : k.label, onSelected: (k) => setState(() => _kind = k)),
        ],
        const Gap(16),
        if (items.isEmpty)
          AppCard(
            child: EmptyState(
              title: _status == RequestStatus.pending ? 'No pending requests' : 'Nothing here',
              message: _status == RequestStatus.pending ? 'You are all caught up.' : 'No requests match this filter.',
              icon: Icons.task_alt,
            ),
          )
        else
          ResponsiveGrid(minTileWidth: 400, spacing: 12, children: [
            for (final item in items)
              ApprovalCard(
                item: item,
                employeeName: app.nameOf(item.employeeId),
                onApprove: widget.allowActions ? () => act(item, RequestStatus.approved) : null,
                onReject: widget.allowActions ? () => act(item, RequestStatus.rejected) : null,
              ),
          ]),
      ],
    );
  }
}
