import 'package:flutter/material.dart';

class Holiday {
  Holiday({required this.id, required this.date, required this.name, this.type = 'Public'});
  final String id;
  final DateTime date;
  final String name;
  final String type;
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.date,
    required this.author,
    this.audience = 'All employees',
    this.published = true,
    this.pinned = false,
  });

  final String id;
  String title;
  String body;
  String category;
  DateTime date;
  final String author;
  String audience;
  bool published;
  bool pinned;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String type; // attendance | leave | announcement | system | meeting
  bool read;
}

class DocumentItem {
  DocumentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.updated,
    required this.size,
    this.extension = 'PDF',
  });

  final String id;
  final String title;
  final String category; // Employment | HR Policy | Company
  final DateTime updated;
  final String size;
  final String extension;
}

class Payslip {
  Payslip({
    required this.id,
    required this.month,
    required this.basic,
    required this.hra,
    required this.allowances,
    required this.pf,
    required this.professionalTax,
    required this.incomeTax,
  });

  final String id;
  final DateTime month;
  final double basic;
  final double hra;
  final double allowances;
  final double pf;
  final double professionalTax;
  final double incomeTax;

  double get gross => basic + hra + allowances;
  double get deductions => pf + professionalTax + incomeTax;
  double get net => gross - deductions;
}

class Expense {
  Expense({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.status = 'Pending',
    this.hasReceipt = true,
    this.notes = '',
  });

  final String id;
  final String employeeId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  String status; // Pending | Approved | Rejected | Reimbursed
  final bool hasReceipt;
  final String notes;
}

class Meeting {
  Meeting({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.participantIds,
    required this.agenda,
    required this.link,
    this.location = 'Online',
    this.organizerId = '',
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final List<String> participantIds;
  final List<String> agenda;
  final String link;
  final String location;
  final String organizerId;
}

class Asset {
  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.serial,
    this.assignedTo,
    this.status = 'Available',
    this.assignedOn,
  });

  final String id;
  final String name;
  final String type; // Laptop | Monitor | Access Card | Phone | Accessory
  final String serial;
  String? assignedTo;
  String status; // Assigned | Available | Under Repair
  DateTime? assignedOn;
}

class TicketMessage {
  TicketMessage({required this.fromMe, required this.sender, required this.text, required this.time});
  final bool fromMe;
  final String sender;
  final String text;
  final DateTime time;
}

class Ticket {
  Ticket({
    required this.id,
    required this.employeeId,
    required this.subject,
    required this.category,
    required this.priority,
    this.status = 'Open',
    required this.created,
    List<TicketMessage>? messages,
  }) : messages = messages ?? [];

  final String id;
  final String employeeId;
  final String subject;
  final String category;
  final String priority;
  String status; // Open | In Progress | Resolved
  final DateTime created;
  final List<TicketMessage> messages;
}

class AuditLog {
  AuditLog({required this.id, required this.time, required this.actor, required this.action, required this.target, this.icon = Icons.history});
  final String id;
  final DateTime time;
  final String actor;
  final String action;
  final String target;
  final IconData icon;
}

class CalendarEntry {
  CalendarEntry({required this.date, required this.title, required this.type, required this.color, this.subtitle = ''});
  final DateTime date;
  final String title;
  final String type;
  final Color color;
  final String subtitle;
}
