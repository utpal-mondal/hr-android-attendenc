import 'dart:math';

import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../repositories/app_repository.dart';

/// Realistic static data for the demo (documentation section 10).
class MockData {
  static const String employeeId = 'E1001'; // Riya Sen      - employee@demo.com
  static const String managerId = 'E1002'; // Arjun Mehta   - manager@demo.com
  static const String hrId = 'E1003'; // Sneha Kapoor  - hr@demo.com

  static const Map<String, List<int>> _shiftTimes = {
    'General': [9, 30, 18, 30],
    'Morning': [7, 0, 16, 0],
    'Evening': [13, 0, 22, 0],
  };

  static AppSnapshot build() {
    final rnd = Random(11);
    final now = DateTime.now();
    final today = dateOnly(now);
    DateTime day(int offset) => DateTime(today.year, today.month, today.day + offset);
    DateTime at(DateTime d, int h, int m) => DateTime(d.year, d.month, d.day, h, m);

    // ------------------------------------------------------------ organisation
    final branches = [
      Branch(
          id: 'B1',
          name: 'Kolkata HQ',
          city: 'Kolkata',
          address: 'Tower 2, Sector V, Salt Lake, Kolkata 700091',
          workingHours: '09:30 AM - 06:30 PM'),
      Branch(
          id: 'B2',
          name: 'Bangalore Tech Park',
          city: 'Bangalore',
          address: 'Block C, ITPL Main Road, Whitefield, Bangalore 560066',
          workingHours: '09:30 AM - 06:30 PM'),
      Branch(
          id: 'B3',
          name: 'Delhi NCR Office',
          city: 'Delhi',
          address: 'Cyber Hub, DLF Phase 2, Gurugram, Delhi NCR 122002',
          workingHours: '10:00 AM - 07:00 PM'),
    ];

    final shifts = [
      Shift(id: 'S1', name: 'General', startHour: 9, startMinute: 30, endHour: 18, endMinute: 30, graceMinutes: 15),
      Shift(id: 'S2', name: 'Morning', startHour: 7, startMinute: 0, endHour: 16, endMinute: 0, graceMinutes: 10),
      Shift(id: 'S3', name: 'Evening', startHour: 13, startMinute: 0, endHour: 22, endMinute: 0, graceMinutes: 15),
    ];

    final departments = [
      Department(id: 'D1', name: 'Engineering', head: 'Arjun Mehta', description: 'Product engineering, QA and DevOps.'),
      Department(id: 'D2', name: 'Design', head: 'Aditya Rao', description: 'UX research, UI and brand design.'),
      Department(id: 'D3', name: 'Sales', head: 'Kabir Malhotra', description: 'Enterprise sales and business development.'),
      Department(id: 'D4', name: 'Finance', head: 'Meera Iyer', description: 'Accounts, payroll and financial planning.'),
      Department(id: 'D5', name: 'HR', head: 'Sneha Kapoor', description: 'People operations, recruitment and culture.'),
    ];

    // --------------------------------------------------------------- employees
    final employees = <Employee>[];
    void emp(String id, String name, String dept, String desig, String branch, String shift, String? mgr,
        {UserRole role = UserRole.employee, String? email, String gender = 'Female'}) {
      final parts = name.toLowerCase().split(' ');
      employees.add(Employee(
        id: id,
        name: name,
        email: email ?? '${parts.first}.${parts.last}@nexora.demo',
        phone: '+91 9${(800000000 + rnd.nextInt(199999999)).toString()}',
        department: dept,
        designation: desig,
        branch: branch,
        shift: shift,
        managerId: mgr,
        joinDate: day(-(120 + rnd.nextInt(1800))),
        role: role,
        gender: gender,
        address: '${10 + rnd.nextInt(80)}, Green Park Road, $branch',
        emergencyContact: '+91 9${(700000000 + rnd.nextInt(199999999)).toString()}',
      ));
    }

    emp('E1001', 'Riya Sen', 'Engineering', 'Software Engineer', 'Kolkata HQ', 'General', 'E1002', email: 'employee@demo.com');
    emp('E1002', 'Arjun Mehta', 'Engineering', 'Engineering Manager', 'Kolkata HQ', 'General', null,
        role: UserRole.manager, email: 'manager@demo.com', gender: 'Male');
    emp('E1003', 'Sneha Kapoor', 'HR', 'HR Manager', 'Kolkata HQ', 'General', null,
        role: UserRole.hr, email: 'hr@demo.com');
    emp('E1004', 'Kabir Malhotra', 'Sales', 'Sales Manager', 'Delhi NCR Office', 'General', null,
        role: UserRole.manager, gender: 'Male');
    emp('E1005', 'Meera Iyer', 'Finance', 'Finance Manager', 'Bangalore Tech Park', 'General', null,
        role: UserRole.manager);
    emp('E1006', 'Ananya Das', 'Engineering', 'Senior Software Engineer', 'Kolkata HQ', 'General', 'E1002');
    emp('E1007', 'Rohan Gupta', 'Engineering', 'Backend Developer', 'Bangalore Tech Park', 'Morning', 'E1002', gender: 'Male');
    emp('E1008', 'Priya Nair', 'Engineering', 'QA Engineer', 'Bangalore Tech Park', 'General', 'E1002');
    emp('E1009', 'Vikram Singh', 'Engineering', 'DevOps Engineer', 'Delhi NCR Office', 'Evening', 'E1002', gender: 'Male');
    emp('E1010', 'Ishaan Bose', 'Engineering', 'Frontend Developer', 'Kolkata HQ', 'General', 'E1002', gender: 'Male');
    emp('E1011', 'Tanvi Joshi', 'Engineering', 'Mobile Developer', 'Kolkata HQ', 'Morning', 'E1002');
    emp('E1012', 'Debashish Roy', 'Engineering', 'Data Engineer', 'Kolkata HQ', 'General', 'E1002', gender: 'Male');
    emp('E1014', 'Aditya Rao', 'Design', 'Design Lead', 'Bangalore Tech Park', 'General', null,
        role: UserRole.manager, gender: 'Male');
    emp('E1015', 'Neha Verma', 'Design', 'UX Designer', 'Bangalore Tech Park', 'General', 'E1014');
    emp('E1016', 'Sourav Ghosh', 'Design', 'UI Designer', 'Kolkata HQ', 'General', 'E1014', gender: 'Male');
    emp('E1017', 'Pooja Reddy', 'Design', 'Visual Designer', 'Bangalore Tech Park', 'General', 'E1014');
    emp('E1018', 'Rahul Khanna', 'Sales', 'Sales Executive', 'Delhi NCR Office', 'Morning', 'E1004', gender: 'Male');
    emp('E1019', 'Simran Kaur', 'Sales', 'Account Executive', 'Delhi NCR Office', 'General', 'E1004');
    emp('E1020', 'Mohit Agarwal', 'Sales', 'Business Development Executive', 'Kolkata HQ', 'Evening', 'E1004', gender: 'Male');
    emp('E1021', 'Nandini Pillai', 'Sales', 'Sales Executive', 'Bangalore Tech Park', 'General', 'E1004');
    emp('E1022', 'Karan Shah', 'Finance', 'Accountant', 'Bangalore Tech Park', 'General', 'E1005', gender: 'Male');
    emp('E1023', 'Lakshmi Menon', 'Finance', 'Financial Analyst', 'Bangalore Tech Park', 'General', 'E1005');
    emp('E1024', 'Sayantan Dutta', 'Finance', 'Accounts Executive', 'Kolkata HQ', 'General', 'E1005', gender: 'Male');
    emp('E1025', 'Farhan Ali', 'HR', 'HR Executive', 'Kolkata HQ', 'General', 'E1003', gender: 'Male');
    emp('E1026', 'Ritu Saxena', 'HR', 'Talent Recruiter', 'Delhi NCR Office', 'General', 'E1003');
    // one inactive employee for filters
    employees.firstWhere((e) => e.id == 'E1020').active = false;

    // --------------------------------------------------------------- holidays
    final holidays = <Holiday>[
      Holiday(id: 'H1', date: DateTime(2026, 1, 26), name: 'Republic Day', type: 'National'),
      Holiday(id: 'H2', date: DateTime(2026, 3, 4), name: 'Holi', type: 'Festival'),
      Holiday(id: 'H3', date: DateTime(2026, 4, 3), name: 'Good Friday', type: 'Festival'),
      Holiday(id: 'H4', date: DateTime(2026, 5, 1), name: 'May Day', type: 'Public'),
      Holiday(id: 'H5', date: DateTime(2026, 8, 15), name: 'Independence Day', type: 'National'),
      Holiday(id: 'H6', date: DateTime(2026, 9, 14), name: 'Ganesh Chaturthi', type: 'Festival'),
      Holiday(id: 'H7', date: DateTime(2026, 10, 2), name: 'Gandhi Jayanti', type: 'National'),
      Holiday(id: 'H8', date: DateTime(2026, 10, 20), name: 'Vijaya Dashami', type: 'Festival'),
      Holiday(id: 'H9', date: DateTime(2026, 11, 9), name: 'Diwali (Day off)', type: 'Festival'),
      Holiday(id: 'H10', date: DateTime(2026, 12, 25), name: 'Christmas Day', type: 'Public'),
      Holiday(id: 'H11', date: DateTime(2027, 1, 26), name: 'Republic Day', type: 'National'),
    ];
    Holiday? holidayOn(DateTime d) {
      for (final h in holidays) {
        if (sameDay(h.date, d)) return h;
      }
      return null;
    }

    // -------------------------------------------------------------- attendance
    final attendance = <Attendance>[];
    String aid(String emp, DateTime d) => 'A-$emp-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

    for (final e in employees) {
      final st = _shiftTimes[e.shift]!;
      for (var i = 36; i >= 0; i--) {
        final d = day(-i);
        if (d.weekday >= 6) continue;
        final isToday = i == 0;
        if (isToday && e.id == employeeId) continue; // demo employee starts the day fresh
        final hol = holidayOn(d);
        if (hol != null) {
          attendance.add(Attendance(
              id: aid(e.id, d), employeeId: e.id, date: d, status: AttendanceStatus.holiday, office: e.branch, note: hol.name));
          continue;
        }
        // The demo employee has a mostly clean record.
        final r = e.id == employeeId ? rnd.nextDouble() * 0.9 : rnd.nextDouble();
        AttendanceStatus s;
        if (r < 0.70) {
          s = AttendanceStatus.present;
        } else if (r < 0.80) {
          s = AttendanceStatus.late;
        } else if (r < 0.88) {
          s = AttendanceStatus.wfh;
        } else if (r < 0.93) {
          s = AttendanceStatus.leave;
        } else if (r < 0.96) {
          s = AttendanceStatus.halfDay;
        } else {
          s = AttendanceStatus.absent;
        }
        if (isToday && (s == AttendanceStatus.absent || s == AttendanceStatus.halfDay)) s = AttendanceStatus.present;

        if (s == AttendanceStatus.leave || s == AttendanceStatus.absent) {
          attendance.add(Attendance(id: aid(e.id, d), employeeId: e.id, date: d, status: s, office: e.branch));
          continue;
        }
        final startMin = st[0] * 60 + st[1];
        int inMin;
        if (s == AttendanceStatus.late) {
          inMin = startMin + 20 + rnd.nextInt(55);
        } else {
          inMin = startMin - 20 + rnd.nextInt(30);
        }
        final checkIn = at(d, inMin ~/ 60, inMin % 60);
        DateTime? checkOut;
        final breaks = <AttendanceBreak>[];
        if (!isToday) {
          final span = s == AttendanceStatus.halfDay ? 4 * 60 + 10 : 8 * 60 + 45 + rnd.nextInt(105) - 30;
          checkOut = checkIn.add(Duration(minutes: span));
          if (s != AttendanceStatus.halfDay) {
            final bs = checkIn.add(const Duration(hours: 4));
            breaks.add(AttendanceBreak(start: bs, end: bs.add(Duration(minutes: 35 + rnd.nextInt(25)))));
          }
        }
        attendance.add(Attendance(
          id: aid(e.id, d),
          employeeId: e.id,
          date: d,
          status: s,
          checkIn: checkIn,
          checkOut: checkOut,
          breaks: breaks,
          office: s == AttendanceStatus.wfh ? 'Remote (Home)' : e.branch,
        ));
      }
    }

    // ------------------------------------------------------------ leave / WFH
    final leaves = <LeaveRequest>[];
    var lid = 0;
    void leave(String emp, String type, int from, int len, RequestStatus st, String reason,
        {bool half = false, bool attach = false}) {
      lid++;
      leaves.add(LeaveRequest(
        id: 'L$lid',
        employeeId: emp,
        type: type,
        from: day(from),
        to: day(from + len - 1),
        halfDay: half,
        reason: reason,
        status: st,
        appliedOn: day(from - 6),
        hasAttachment: attach,
        reviewerNote: st == RequestStatus.rejected ? 'Project deadline overlap - please reschedule.' : null,
      ));
    }

    leave('E1001', 'Casual Leave', -20, 2, RequestStatus.approved, 'Family function in Durgapur.');
    leave('E1001', 'Sick Leave', -45, 1, RequestStatus.approved, 'Viral fever and rest advised by doctor.', attach: true);
    leave('E1001', 'Earned Leave', 10, 3, RequestStatus.pending, 'Short vacation to Darjeeling with family.');
    leave('E1001', 'Casual Leave', -60, 1, RequestStatus.rejected, 'Personal work.');
    leave('E1006', 'Earned Leave', 5, 3, RequestStatus.pending, "Sister's wedding ceremonies.");
    leave('E1010', 'Sick Leave', -2, 1, RequestStatus.approved, 'Migraine.');
    leave('E1011', 'Casual Leave', 3, 1, RequestStatus.pending, 'Bank and property registration work.');
    leave('E1007', 'Earned Leave', 15, 5, RequestStatus.approved, 'Travel to hometown.');
    leave('E1018', 'Casual Leave', 2, 1, RequestStatus.pending, 'Visa appointment.');
    leave('E1022', 'Sick Leave', -5, 2, RequestStatus.approved, 'Dental procedure.', attach: true);
    leave('E1025', 'Comp Off', 7, 1, RequestStatus.pending, 'Worked on the recruitment drive weekend.');
    leave('E1014', 'Casual Leave', -10, 1, RequestStatus.approved, 'Moving to a new apartment.');
    leave('E1024', 'Earned Leave', -30, 4, RequestStatus.approved, 'Pilgrimage trip.');
    leave('E1020', 'Casual Leave', 1, 1, RequestStatus.rejected, 'Personal reasons.');
    leave('E1008', 'Sick Leave', 4, 2, RequestStatus.pending, 'Scheduled medical check-up.', attach: true);

    final wfh = <WFHRequest>[];
    var wid = 0;
    void wfhReq(String emp, int from, int len, RequestStatus st, String reason) {
      wid++;
      wfh.add(WFHRequest(
          id: 'W$wid',
          employeeId: emp,
          from: day(from),
          to: day(from + len - 1),
          reason: reason,
          status: st,
          appliedOn: day(from - 3)));
    }

    wfhReq('E1001', 3, 1, RequestStatus.pending, 'Plumbing work at home; need to be present.');
    wfhReq('E1001', -8, 1, RequestStatus.approved, 'Waiting for a courier delivery.');
    wfhReq('E1001', -25, 2, RequestStatus.rejected, 'Sprint demo requires on-site presence.');
    wfhReq('E1009', 2, 2, RequestStatus.pending, 'Focused work on infrastructure migration.');
    wfhReq('E1012', 4, 1, RequestStatus.pending, 'Internet installation at new residence.');
    wfhReq('E1008', -3, 1, RequestStatus.approved, 'Medical appointment in the morning.');
    wfhReq('E1019', -1, 1, RequestStatus.approved, 'Client calls in different time zone.');
    wfhReq('E1021', 6, 2, RequestStatus.pending, 'Family emergency at home.');

    final regs = <RegularizationRequest>[];
    var rid = 0;
    void reg(String emp, int dayOffset, int inH, int inM, int outH, int outM, RequestStatus st, String reason) {
      rid++;
      final d = day(dayOffset);
      regs.add(RegularizationRequest(
          id: 'R$rid',
          employeeId: emp,
          date: d,
          requestedIn: at(d, inH, inM),
          requestedOut: at(d, outH, outM),
          reason: reason,
          status: st,
          appliedOn: day(dayOffset + 1),
          hasAttachment: rid % 2 == 0));
    }

    reg('E1001', -3, 9, 30, 18, 30, RequestStatus.pending, 'Forgot to check out before leaving for the client site.');
    reg('E1001', -12, 9, 40, 18, 45, RequestStatus.approved, 'QR scanner was not working at the entrance.');
    reg('E1008', -2, 9, 35, 18, 40, RequestStatus.pending, 'Mobile app crashed during check-in.');
    reg('E1012', -4, 10, 0, 19, 0, RequestStatus.pending, 'Was at the client location for a workshop.');
    reg('E1023', -5, 9, 30, 18, 30, RequestStatus.approved, 'Power outage at the branch.');

    // --------------------------------------------------------- announcements
    final announcements = <Announcement>[
      Announcement(
          id: 'AN1',
          title: 'Diwali celebrations & office closure',
          body:
              'The office will remain closed on 9 November for Diwali. Join us for the festive lunch and rangoli competition on 6 November at all branches. Sweets boxes will be distributed at the reception.',
          category: 'Holiday',
          date: day(-1),
          author: 'Sneha Kapoor',
          pinned: true),
      Announcement(
          id: 'AN2',
          title: 'Updated hybrid work policy effective next month',
          body:
              'Employees may now work from home up to 6 days a month with manager approval. Please review the revised policy in the Documents section and raise a helpdesk ticket for any questions.',
          category: 'Policy',
          date: day(-3),
          author: 'Sneha Kapoor'),
      Announcement(
          id: 'AN3',
          title: 'Quarterly Town Hall - Q3 results',
          body:
              'Our CEO will share Q3 achievements and the roadmap for the coming quarter. The session will be broadcast live from Kolkata HQ and available on the meeting link for remote employees.',
          category: 'Event',
          date: day(-5),
          author: 'Leadership Team'),
      Announcement(
          id: 'AN4',
          title: 'Health insurance enrolment window open',
          body:
              'Annual health insurance enrolment is open till the end of the month. You can add dependants and choose a top-up cover. Contact HR for assistance with documentation.',
          category: 'HR',
          date: day(-8),
          author: 'HR Team'),
      Announcement(
          id: 'AN5',
          title: 'Bangalore office moving to Block C',
          body:
              'From the first Monday of next month the Bangalore team will operate from Block C, Floor 4. New access cards will be issued at the reception on Friday.',
          category: 'News',
          date: day(-12),
          author: 'Facilities',
          audience: 'Bangalore Tech Park'),
      Announcement(
          id: 'AN6',
          title: 'Security awareness training is mandatory',
          body:
              'All employees must complete the 30-minute information security course before the end of next week. Certificates will be recorded in your profile.',
          category: 'Policy',
          date: day(-15),
          author: 'IT Security'),
      Announcement(
          id: 'AN7',
          title: 'Hackathon 2026 - registrations opening soon',
          body:
              'Draft: Details of the internal hackathon, team sizes and prizes will be announced after leadership review.',
          category: 'Event',
          date: day(0),
          author: 'Sneha Kapoor',
          published: false),
    ];

    // ---------------------------------------------------------- notifications
    final notifications = <AppNotification>[
      AppNotification(
          id: 'N1',
          title: 'Leave request pending',
          body: 'Your Earned Leave request is awaiting manager approval.',
          time: now.subtract(const Duration(minutes: 35)),
          type: 'leave'),
      AppNotification(
          id: 'N2',
          title: 'Town hall reminder',
          body: 'Quarterly Town Hall starts tomorrow at 4:00 PM.',
          time: now.subtract(const Duration(hours: 3)),
          type: 'meeting'),
      AppNotification(
          id: 'N3',
          title: 'New announcement',
          body: 'Diwali celebrations & office closure.',
          time: now.subtract(const Duration(hours: 5)),
          type: 'announcement'),
      AppNotification(
          id: 'N4',
          title: 'Regularization submitted',
          body: 'Your attendance correction request is with your manager.',
          time: now.subtract(const Duration(days: 1, hours: 2)),
          type: 'attendance',
          read: true),
      AppNotification(
          id: 'N5',
          title: 'Payslip available',
          body: 'Your payslip for last month is ready to download.',
          time: now.subtract(const Duration(days: 1, hours: 6)),
          type: 'system',
          read: true),
      AppNotification(
          id: 'N6',
          title: 'WFH request approved',
          body: 'Your work from home request was approved by Arjun Mehta.',
          time: now.subtract(const Duration(days: 4)),
          type: 'leave',
          read: true),
      AppNotification(
          id: 'N7',
          title: 'Security training due',
          body: 'Complete the mandatory security awareness course.',
          time: now.subtract(const Duration(days: 6)),
          type: 'system'),
      AppNotification(
          id: 'N8',
          title: 'Expense reimbursed',
          body: 'Your travel expense claim has been reimbursed.',
          time: now.subtract(const Duration(days: 9)),
          type: 'system',
          read: true),
    ];

    // -------------------------------------------------------------- documents
    DocumentItem doc(String id, String title, String cat, int ago, String size, [String ext = 'PDF']) =>
        DocumentItem(id: id, title: title, category: cat, updated: day(-ago), size: size, extension: ext);
    final documents = <DocumentItem>[
      doc('DOC1', 'Offer Letter - Riya Sen', 'Employment', 700, '212 KB'),
      doc('DOC2', 'Appointment Letter', 'Employment', 690, '184 KB'),
      doc('DOC3', 'Non-Disclosure Agreement', 'Employment', 690, '98 KB'),
      doc('DOC4', 'Employee Handbook 2026', 'HR Policy', 40, '2.4 MB'),
      doc('DOC5', 'Leave & Attendance Policy', 'HR Policy', 22, '640 KB'),
      doc('DOC6', 'Work From Home Policy', 'HR Policy', 3, '410 KB'),
      doc('DOC7', 'Code of Conduct', 'HR Policy', 120, '860 KB'),
      doc('DOC8', 'POSH Policy', 'HR Policy', 200, '520 KB'),
      doc('DOC9', 'Information Security Guidelines', 'Company', 30, '1.1 MB'),
      doc('DOC10', 'Organisation Chart', 'Company', 15, '780 KB', 'PNG'),
      doc('DOC11', 'Holiday List 2026', 'Company', 60, '96 KB'),
      doc('DOC12', 'Expense Reimbursement Guide', 'Company', 90, '350 KB', 'DOCX'),
    ];

    // --------------------------------------------------------------- payslips
    final payslips = <Payslip>[];
    for (var m = 1; m <= 6; m++) {
      final month = DateTime(today.year, today.month - m, 1);
      final bonus = m == 3 ? 6000.0 : 0.0;
      payslips.add(Payslip(
        id: 'PS$m',
        month: month,
        basic: 48000,
        hra: 19200,
        allowances: 21800 + bonus,
        pf: 5760,
        professionalTax: 200,
        incomeTax: 7350 + (bonus > 0 ? 900 : 0),
      ));
    }

    // --------------------------------------------------------------- expenses
    final expenses = <Expense>[
      Expense(id: 'X1', employeeId: 'E1001', title: 'Client visit cab fare', category: 'Travel', amount: 1850, date: day(-6), status: 'Pending', notes: 'Kolkata to Sector V and back.'),
      Expense(id: 'X2', employeeId: 'E1001', title: 'Team lunch - sprint release', category: 'Meals', amount: 3200, date: day(-18), status: 'Approved'),
      Expense(id: 'X3', employeeId: 'E1001', title: 'Wireless keyboard', category: 'Equipment', amount: 2499, date: day(-33), status: 'Reimbursed'),
      Expense(id: 'X4', employeeId: 'E1001', title: 'Conference ticket', category: 'Training', amount: 7500, date: day(-50), status: 'Rejected', notes: 'Not pre-approved.'),
      Expense(id: 'X5', employeeId: 'E1001', title: 'Airport transfer', category: 'Travel', amount: 950, date: day(-70), status: 'Reimbursed'),
      Expense(id: 'X6', employeeId: 'E1006', title: 'Cloud certification exam', category: 'Training', amount: 12500, date: day(-4), status: 'Pending'),
      Expense(id: 'X7', employeeId: 'E1018', title: 'Client dinner', category: 'Meals', amount: 6400, date: day(-3), status: 'Pending'),
      Expense(id: 'X8', employeeId: 'E1009', title: 'Hotel - data centre visit', category: 'Travel', amount: 9800, date: day(-9), status: 'Approved'),
      Expense(id: 'X9', employeeId: 'E1015', title: 'Design tool subscription', category: 'Software', amount: 4200, date: day(-12), status: 'Approved'),
      Expense(id: 'X10', employeeId: 'E1022', title: 'Stationery & printing', category: 'Office', amount: 1350, date: day(-14), status: 'Reimbursed'),
    ];

    // --------------------------------------------------------------- meetings
    Meeting meet(String id, String title, DateTime start, int minutes, List<String> people, List<String> agenda,
        {String location = 'Online', String org = 'E1002'}) {
      return Meeting(
        id: id,
        title: title,
        start: start,
        end: start.add(Duration(minutes: minutes)),
        participantIds: people,
        agenda: agenda,
        link: 'https://meet.nexora.demo/${id.toLowerCase()}',
        location: location,
        organizerId: org,
      );
    }

    final meetings = <Meeting>[
      meet('M1', 'Daily Stand-up', at(today, 11, 0), 15, ['E1001', 'E1002', 'E1006', 'E1010', 'E1011'],
          ['Yesterday\'s progress', 'Today\'s plan', 'Blockers']),
      meet('M2', 'Sprint Planning', at(day(1), 15, 0), 60, ['E1001', 'E1002', 'E1006', 'E1007', 'E1008', 'E1012'],
          ['Sprint goals', 'Backlog grooming', 'Capacity planning', 'Risks'],
          location: 'Conf Room Orion, Kolkata HQ'),
      meet('M3', 'Quarterly Town Hall', at(day(1), 16, 0), 90, ['E1001', 'E1002', 'E1003', 'E1004', 'E1005'],
          ['Q3 business review', 'Product roadmap', 'Open Q&A'],
          org: 'E1003', location: 'Auditorium + Online'),
      meet('M4', '1:1 with Manager', at(day(2), 12, 0), 30, ['E1001', 'E1002'], ['Career growth', 'Feedback', 'Upcoming goals']),
      meet('M5', 'Design Review - HR Portal', at(day(3), 14, 30), 45, ['E1001', 'E1010', 'E1015', 'E1016'],
          ['Walkthrough of new screens', 'Accessibility review', 'Handoff notes'], org: 'E1014'),
      meet('M6', 'Release Retrospective', at(day(5), 17, 0), 60, ['E1001', 'E1002', 'E1006', 'E1008', 'E1009'],
          ['What went well', 'What to improve', 'Action items']),
    ];

    // ----------------------------------------------------------------- assets
    final assets = <Asset>[
      Asset(id: 'AS1', name: 'Dell Latitude 7440', type: 'Laptop', serial: 'DL7440-8841', assignedTo: 'E1001', status: 'Assigned', assignedOn: day(-600)),
      Asset(id: 'AS2', name: 'LG UltraFine 27" Monitor', type: 'Monitor', serial: 'LG27-5521', assignedTo: 'E1001', status: 'Assigned', assignedOn: day(-590)),
      Asset(id: 'AS3', name: 'Access Card #KOL-2031', type: 'Access Card', serial: 'KOL-2031', assignedTo: 'E1001', status: 'Assigned', assignedOn: day(-600)),
      Asset(id: 'AS4', name: 'Jabra Evolve2 Headset', type: 'Accessory', serial: 'JB-9932', assignedTo: 'E1001', status: 'Assigned', assignedOn: day(-320)),
      Asset(id: 'AS5', name: 'MacBook Pro 14"', type: 'Laptop', serial: 'MBP14-1120', assignedTo: 'E1006', status: 'Assigned', assignedOn: day(-400)),
      Asset(id: 'AS6', name: 'MacBook Pro 14"', type: 'Laptop', serial: 'MBP14-1187', assignedTo: 'E1015', status: 'Assigned', assignedOn: day(-210)),
      Asset(id: 'AS7', name: 'ThinkPad T14', type: 'Laptop', serial: 'TP14-7741', assignedTo: 'E1009', status: 'Assigned', assignedOn: day(-150)),
      Asset(id: 'AS8', name: 'Dell Latitude 7440', type: 'Laptop', serial: 'DL7440-9012', status: 'Available'),
      Asset(id: 'AS9', name: 'Dell 24" Monitor', type: 'Monitor', serial: 'DL24-3301', status: 'Available'),
      Asset(id: 'AS10', name: 'iPhone 14 (Test device)', type: 'Phone', serial: 'IP14-7781', assignedTo: 'E1011', status: 'Assigned', assignedOn: day(-90)),
      Asset(id: 'AS11', name: 'Access Card #BLR-1177', type: 'Access Card', serial: 'BLR-1177', status: 'Available'),
      Asset(id: 'AS12', name: 'ThinkPad E15', type: 'Laptop', serial: 'TPE15-2210', status: 'Under Repair'),
    ];

    // ---------------------------------------------------------------- tickets
    final tickets = <Ticket>[
      Ticket(
        id: 'T-1042',
        employeeId: 'E1001',
        subject: 'VPN disconnects every few minutes',
        category: 'IT Support',
        priority: 'High',
        status: 'In Progress',
        created: now.subtract(const Duration(days: 2)),
        messages: [
          TicketMessage(fromMe: true, sender: 'Riya Sen', text: 'My VPN keeps dropping when I work from home. Happens every 10 minutes or so.', time: now.subtract(const Duration(days: 2))),
          TicketMessage(fromMe: false, sender: 'IT Helpdesk', text: 'Thanks Riya. Could you share your VPN client version and OS?', time: now.subtract(const Duration(days: 2, hours: -1))),
          TicketMessage(fromMe: true, sender: 'Riya Sen', text: 'Client 5.2.1 on Windows 11.', time: now.subtract(const Duration(days: 1, hours: 20))),
          TicketMessage(fromMe: false, sender: 'IT Helpdesk', text: 'We are rolling out a patched profile. Please reinstall the profile from the IT portal.', time: now.subtract(const Duration(days: 1))),
        ],
      ),
      Ticket(
        id: 'T-1031',
        employeeId: 'E1001',
        subject: 'Salary certificate for visa application',
        category: 'HR Query',
        priority: 'Medium',
        status: 'Resolved',
        created: now.subtract(const Duration(days: 14)),
        messages: [
          TicketMessage(fromMe: true, sender: 'Riya Sen', text: 'I need a salary certificate addressed to the consulate.', time: now.subtract(const Duration(days: 14))),
          TicketMessage(fromMe: false, sender: 'HR Team', text: 'Certificate has been emailed to you. Please confirm receipt.', time: now.subtract(const Duration(days: 12))),
        ],
      ),
      Ticket(
        id: 'T-1015',
        employeeId: 'E1001',
        subject: 'Request for second monitor stand',
        category: 'Facilities',
        priority: 'Low',
        status: 'Open',
        created: now.subtract(const Duration(days: 5)),
        messages: [
          TicketMessage(fromMe: true, sender: 'Riya Sen', text: 'Could I please get an adjustable monitor stand for my desk?', time: now.subtract(const Duration(days: 5))),
        ],
      ),
    ];

    // ------------------------------------------------------------- audit logs
    AuditLog log(String id, int minsAgo, String action, String target, IconData icon) => AuditLog(
        id: id,
        time: now.subtract(Duration(minutes: minsAgo)),
        actor: 'Sneha Kapoor',
        action: action,
        target: target,
        icon: icon);
    final auditLogs = <AuditLog>[
      log('AU1', 12, 'Approved leave request', 'Ishaan Bose - Sick Leave', Icons.check_circle_outline),
      log('AU2', 55, 'Published announcement', 'Diwali celebrations & office closure', Icons.campaign_outlined),
      log('AU3', 190, 'Added employee', 'Ritu Saxena (Talent Recruiter)', Icons.person_add_alt_outlined),
      log('AU4', 420, 'Updated shift', 'Evening shift grace period 15 min', Icons.schedule),
      log('AU5', 1500, 'Rejected leave request', 'Mohit Agarwal - Casual Leave', Icons.cancel_outlined),
      log('AU6', 1700, 'Changed holiday calendar', 'Added Vijaya Dashami', Icons.event_outlined),
      log('AU7', 2900, 'Deactivated employee', 'Mohit Agarwal', Icons.person_off_outlined),
      log('AU8', 4300, 'Updated branch details', 'Bangalore Tech Park - address', Icons.apartment),
      log('AU9', 5600, 'Assigned asset', 'ThinkPad T14 to Vikram Singh', Icons.laptop_mac),
      log('AU10', 7200, 'Approved expense claim', 'Hotel - data centre visit', Icons.receipt_long_outlined),
      log('AU11', 8800, 'Exported report', 'Monthly attendance report', Icons.file_download_outlined),
      log('AU12', 10100, 'Updated leave policy', 'Casual leave quota set to 12 days', Icons.rule_folder_outlined),
    ];

    return AppSnapshot(
      employees: employees,
      departments: departments,
      branches: branches,
      shifts: shifts,
      holidays: holidays,
      attendance: attendance,
      leaves: leaves,
      wfhRequests: wfh,
      regularizations: regs,
      announcements: announcements,
      notifications: notifications,
      documents: documents,
      payslips: payslips,
      expenses: expenses,
      meetings: meetings,
      assets: assets,
      tickets: tickets,
      auditLogs: auditLogs,
    );
  }
}
