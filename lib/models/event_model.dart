import 'user_model.dart';

class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? course;
  final String? section;
  final String? yearLevel;
  final String? department;
  final String? college;
  final String createdBy;
  final String createdByRole;
  final String status;
  final bool isActive;
  final String? qrCodeData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Attendance>? attendances;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    this.location,
    this.course,
    this.section,
    this.yearLevel,
    this.department,
    this.college,
    required this.createdBy,
    required this.createdByRole,
    required this.status,
    required this.isActive,
    this.qrCodeData,
    required this.createdAt,
    required this.updatedAt,
    this.attendances,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'])
          : DateTime.now(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      location: json['location'],
      course: json['course'],
      section: json['section'],
      yearLevel: json['year_level'],
      department: json['department'],
      college: json['college'],
      createdBy: json['created_by'] ?? '',
      createdByRole: json['created_by_role'] ?? 'faculty',
      status: json['status'] ?? 'scheduled',
      isActive: json['is_active'] ?? true,
      qrCodeData: json['qr_code_data'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      attendances: json['attendances'] != null
          ? (json['attendances'] as List)
              .map((e) => Attendance.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_time': startTime.toIso8601String().split('T')[1].substring(0, 5),
      'end_time': endTime.toIso8601String().split('T')[1].substring(0, 5),
      'location': location,
      'course': course,
      'section': section,
      'year_level': yearLevel,
      'department': department,
      'college': college,
    };
  }
}

class Attendance {
  final int id;
  final int eventID;
  final String studentID;
  final String status;
  final DateTime markedAt;
  final String? markedBy;
  final String? markedByRole;
  final String method;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInStatus;
  final String? checkOutStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Event? event;
  final User? student;

  Attendance({
    required this.id,
    required this.eventID,
    required this.studentID,
    required this.status,
    required this.markedAt,
    this.markedBy,
    this.markedByRole,
    required this.method,
    this.latitude,
    this.longitude,
    this.notes,
    this.checkInTime,
    this.checkOutTime,
    this.checkInStatus,
    this.checkOutStatus,
    required this.createdAt,
    required this.updatedAt,
    this.event,
    this.student,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      eventID: json['event_id'] ?? 0,
      studentID: json['student_id'] ?? '',
      status: json['status'] ?? 'present',
      markedAt: json['marked_at'] != null
          ? DateTime.parse(json['marked_at'])
          : DateTime.now(),
      markedBy: json['marked_by'],
      markedByRole: json['marked_by_role'],
      method: json['method'] ?? 'qr_scan',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      notes: json['notes'],
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      checkInStatus: json['check_in_status'],
      checkOutStatus: json['check_out_status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      student: json['student'] != null ? User.fromJson(json['student']) : null,
    );
  }
}

