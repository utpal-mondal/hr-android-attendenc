import 'package:flutter_test/flutter_test.dart';
import 'package:office_management/core/utils/formatters.dart';
import 'package:office_management/mock_data/mock_data.dart';
import 'package:office_management/models/enums.dart';

void main() {
  test('Indian currency grouping', () {
    expect(Fmt.money(123456), '\u20B91,23,456');
    expect(Fmt.money(950), '\u20B9950');
  });

  test('Duration formatting', () {
    expect(Fmt.duration(const Duration(hours: 7, minutes: 5)), '7h 05m');
    expect(Fmt.clock(const Duration(hours: 1, minutes: 2, seconds: 3)), '01:02:03');
  });

  test('Mock data has demo accounts for every role', () {
    final s = MockData.build();
    expect(s.employees.where((e) => e.role == UserRole.hr), isNotEmpty);
    expect(s.employees.any((e) => e.id == MockData.employeeId), isTrue);
    expect(s.employees.where((e) => e.managerId == MockData.managerId).length, greaterThan(3));
  });
}
