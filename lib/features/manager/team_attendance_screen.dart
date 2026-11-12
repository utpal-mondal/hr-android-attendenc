import 'package:office_management/core/common.dart';

import 'attendance_board.dart';

class TeamAttendanceScreen extends StatelessWidget {
  const TeamAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Team Attendance',
      subtitle: 'Daily status for your team',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        final app = context.watch<AppController>();
        return AttendanceBoard(ids: app.teamIds, profileBase: '/manager/team');
      },
    );
  }
}
