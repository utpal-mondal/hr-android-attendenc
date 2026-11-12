import 'package:office_management/core/common.dart';
import 'package:office_management/features/manager/approvals_view.dart';
import 'package:office_management/features/manager/attendance_board.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Attendance',
      subtitle: 'Company-wide daily attendance',
      shimmer: ShimmerLayout.list,
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Daily board'), icon: Icon(Icons.fingerprint, size: 18)),
                ButtonSegment(value: 1, label: Text('Corrections'), icon: Icon(Icons.edit_calendar_outlined, size: 18)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const Gap(18),
            if (_tab == 0)
              const AttendanceBoard(showDepartmentFilter: true, profileBase: '/admin/employees')
            else
              const ApprovalsView(kinds: {ApprovalKind.regularization}),
          ],
        );
      },
    );
  }
}
