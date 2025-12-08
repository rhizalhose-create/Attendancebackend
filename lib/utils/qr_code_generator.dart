import 'dart:convert';
import '../models/user_model.dart';

class QRCodeGenerator {
  /// Generates QR code data string with student ID only
  static String generateUserQRData(User user) {
    // Only use student ID for QR code
    final studentID = user.studentID.isNotEmpty ? user.studentID : 'UNKNOWN';
    
    // Return simple format: "student:STUDENTID"
    return 'student:$studentID';
  }

  /// Parses QR code data and extracts student ID (for backward compatibility)
  static String? extractStudentID(String qrData) {
    try {
      // Try to parse as JSON first
      final data = jsonDecode(qrData);
      if (data is Map && data.containsKey('student_id')) {
        return data['student_id'] as String?;
      }
    } catch (e) {
      // Not JSON, try old format "student:STUDENTID"
      if (qrData.startsWith('student:')) {
        final parts = qrData.split(':');
        if (parts.length >= 2) {
          return parts[1];
        }
      } else {
        // Assume it's just the student ID
        return qrData.trim();
      }
    }
    return null;
  }

  /// Parses QR code data and returns full user data if available
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      // Not JSON format, return null
    }
    return null;
  }
}

