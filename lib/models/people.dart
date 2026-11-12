import 'enums.dart';

class Employee {
  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.designation,
    required this.branch,
    required this.shift,
    this.managerId,
    required this.joinDate,
    this.active = true,
    this.role = UserRole.employee,
    this.gender = 'Not specified',
    this.address = '',
    this.emergencyContact = '',
    this.employmentType = 'Full-time',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final String branch;
  final String shift;
  final String? managerId;
  final DateTime joinDate;
  bool active;
  final UserRole role;
  final String gender;
  final String address;
  final String emergencyContact;
  final String employmentType;

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class Department {
  Department({required this.id, required this.name, required this.head, required this.description});
  final String id;
  final String name;
  final String head;
  final String description;
}

class Branch {
  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.workingHours,
    required this.city,
  });
  final String id;
  final String name;
  final String address;
  final String workingHours;
  final String city;
}

class Shift {
  Shift({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.graceMinutes = 15,
  });
  final String id;
  String name;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  int graceMinutes;
}
