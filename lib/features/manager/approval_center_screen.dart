import 'package:office_management/core/common.dart';

import 'approvals_view.dart';

class ApprovalCenterScreen extends StatelessWidget {
  const ApprovalCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Approval Center',
      subtitle: 'Leave, WFH and attendance corrections',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        return ApprovalsView(ids: app.teamIds);
      },
    );
  }
}
