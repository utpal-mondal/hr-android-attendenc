import 'package:flutter_test/flutter_test.dart';
import 'package:office_management/controllers/app_controller.dart';
import 'package:office_management/data/api/api_mappers.dart';
import 'package:office_management/features/attendance/punch_location_view.dart';
import 'package:office_management/models/models.dart';
import 'package:office_management/repositories/mock_app_repository.dart';

void main() {
  group('WFH day rule', () {
    final app = AppController(MockAppRepository());

    test('every Wednesday is WFH', () {
      expect(app.isWfhDay('E1', DateTime(2026, 11, 18)), isTrue); // Wednesday
      expect(app.isWfhDay('E1', DateTime(2026, 11, 19)), isFalse); // Thursday
    });

    test('an approved WFH request makes that day WFH, a pending one does not', () {
      app.wfhRequests = [
        WFHRequest(id: 'W1', employeeId: 'E1', from: DateTime(2026, 11, 19), to: DateTime(2026, 11, 20), reason: 'x', status: RequestStatus.approved, appliedOn: DateTime(2026, 11, 1)),
        WFHRequest(id: 'W2', employeeId: 'E2', from: DateTime(2026, 11, 19), to: DateTime(2026, 11, 19), reason: 'x', appliedOn: DateTime(2026, 11, 1)),
      ];
      expect(app.isWfhDay('E1', DateTime(2026, 11, 20)), isTrue);
      expect(app.isWfhDay('E1', DateTime(2026, 11, 23)), isFalse);
      expect(app.isWfhDay('E2', DateTime(2026, 11, 19)), isFalse);
    });

    test('haversine distance is about right', () {
      // ~1 km due north.
      expect(AppController.distanceMeters(22.5726, 88.3639, 22.5816, 88.3639), closeTo(1000, 10));
    });
  });

  group('API attendance mapping', () {
    test('maps wfh status and punch locations', () {
      final a = attendanceFromJson({
        'id': 7,
        'staff_id': 3,
        'work_date': '2026-11-18',
        'status': 'wfh',
        'check_in_at': '2026-11-18T04:00:00+00:00',
        'check_out_at': '2026-11-18T12:30:00+00:00',
        'check_in_location': {'latitude': 22.5816, 'longitude': '88.3639', 'accuracy_meters': 12, 'distance_from_office_meters': 1001, 'office_name': 'Kolkata HQ'},
        'check_out_location': null,
      });
      expect(a.status, AttendanceStatus.wfh);
      expect(a.checkInLocation?.distanceFromOfficeMeters, 1001);
      expect(a.checkInLocation?.officeName, 'Kolkata HQ');
      expect(a.checkOutLocation, isNull);
      // WFH has no distance limit: only the place is shown, never "km from office".
      expect(attendancePlaceSummary(a), 'WFH · In: Location recorded · Out: No location');
    });

    test('office punches read as "At office"', () {
      const l = PunchLocation(latitude: 22.5727, longitude: 88.3639, accuracyMeters: 8, distanceFromOfficeMeters: 11);
      expect(punchPlaceLabel(l), 'At office');
      expect(punchPlaceLabel(l, wfh: true), 'Location recorded');
      expect(punchPlaceLabel(null), 'No location');
    });
  });
}
