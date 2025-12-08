class User {
  final String studentID;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? course;
  final String? yearLevel;
  final String? section;
  final String? department;
  final String? college;
  final String? contactNumber;
  final String? address;
  final String role;
  final bool isVerified;
  final String? qrCodeData;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  User({
    required this.studentID,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.course,
    this.yearLevel,
    this.section,
    this.department,
    this.college,
    this.contactNumber,
    this.address,
    required this.role,
    required this.isVerified,
    this.qrCodeData,
    this.profilePicture,
    required this.createdAt,
    this.verifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      studentID: json['student_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      course: json['course'],
      yearLevel: json['year_level'],
      section: json['section'],
      department: json['department'],
      college: json['college'],
      contactNumber: json['contact_number'],
      address: json['address'],
      role: json['role'] ?? 'student',
      isVerified: json['is_verified'] ?? false,
      qrCodeData: json['qr_code_data'],
      profilePicture: json['profile_picture'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentID,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'course': course,
      'year_level': yearLevel,
      'section': section,
      'department': department,
      'college': college,
      'contact_number': contactNumber,
      'address': address,
      'role': role,
      'is_verified': isVerified,
      'qr_code_data': qrCodeData,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}

