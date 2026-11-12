import 'package:office_management/core/common.dart';

import 'reports_view.dart';

class TeamReportsScreen extends StatelessWidget {
  const TeamReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Team Reports',
      subtitle: 'Attendance, late arrivals, overtime and leave',
      builder: (context) {
        final app = context.watch<AppController>();
        return ReportsView(ids: app.teamIds);
      },
    );
  }
}
