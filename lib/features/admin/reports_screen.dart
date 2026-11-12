import 'package:office_management/core/common.dart';
import 'package:office_management/features/manager/reports_view.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Reports & Analytics',
      subtitle: 'Company-wide workforce insights',
      builder: (context) => const ReportsView(includeDepartments: true),
    );
  }
}
