import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // For web: use localhost
  // For mobile/emulator: use 10.0.2.2 for Android emulator or your computer's IP
  // For iOS simulator: use localhost
  // For physical device, use your computer's IP address
  // Change this to your computer's IP address when testing on physical device
  // To find your IP: Windows: ipconfig | findstr IPv4, Mac/Linux: ifconfig or ip addr
  static const String baseUrl = 'http://192.168.1.13:3000';
  // Alternative URLs:
  // - For Android emulator: 'http://10.0.2.2:3000'
  // - For web/iOS simulator: 'http://localhost:3000'
  // - For physical device: 'http://192.168.1.13:3000' (your computer's IP)
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final studentID = prefs.getString('student_id');
        if (studentID != null) {
          options.headers['Authorization'] = 'Bearer $studentID';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle unauthorized
        }
        return handler.next(error);
      },
    ));
  }

  // Auth endpoints
  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/register', data: data);
  }

  Future<Response> login(String studentID, String password) async {
    return await _dio.post('/login', data: {
      'student_id': studentID,
      'password': password,
    });
  }

  Future<Response> loginByEmail(String email, String password) async {
    return await _dio.post('/login/email', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> verifyEmail(String email, String code) async {
    return await _dio.post('/verify', data: {
      'email': email,
      'code': code,
    });
  }

  Future<Response> forgotPassword(String email) async {
    return await _dio.post('/forgot-password', data: {'email': email});
  }

  Future<Response> resetPassword(String email, String code, String newPassword) async {
    return await _dio.post('/reset-password', data: {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<Response> resendResetCode(String email) async {
    return await _dio.post('/resend-reset-code', data: {'email': email});
  }

  // Event endpoints
  Future<Response> getAllEvents({Map<String, dynamic>? filters}) async {
    return await _dio.get('/events', queryParameters: filters);
  }

  Future<Response> getEvent(int id) async {
    return await _dio.get('/events/$id');
  }

  Future<Response> getMyEvents() async {
    return await _dio.get('/events/my-events');
  }

  Future<Response> createEvent(Map<String, dynamic> data) async {
    return await _dio.post('/events', data: data);
  }

  Future<Response> updateEvent(int id, Map<String, dynamic> data) async {
    return await _dio.put('/events/$id', data: data);
  }

  Future<Response> deleteEvent(int id) async {
    return await _dio.delete('/events/$id');
  }

  // Attendance endpoints
  Future<Response> markAttendance(Map<String, dynamic> data) async {
    return await _dio.post('/attendance/mark', data: data);
  }

  Future<Response> getMyAttendance({Map<String, dynamic>? filters}) async {
    return await _dio.get('/attendance/my-attendance', queryParameters: filters);
  }

  Future<Response> getAttendanceStats({String? studentID, int? eventID}) async {
    final params = <String, dynamic>{};
    if (studentID != null) params['student_id'] = studentID;
    if (eventID != null) params['event_id'] = eventID;
    return await _dio.get('/attendance/stats', queryParameters: params);
  }

  Future<Response> getAttendanceByEvent(int eventID) async {
    return await _dio.get('/events/$eventID/attendance');
  }

  Future<Response> updateAttendanceStatus(int attendanceID, String status, {String? notes}) async {
    return await _dio.put('/attendance/$attendanceID/status', data: {
      'status': status,
      if (notes != null) 'notes': notes,
    });
  }

  // Admin endpoints
  Future<Response> getAllUsers() async {
    return await _dio.get('/admin/users');
  }

  Future<Response> getUserByStudentID(String studentID) async {
    return await _dio.get('/admin/users/$studentID');
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/users/me');
  }

  Future<Response> promoteUser(String studentID, String role) async {
    return await _dio.post('/admin/promote', data: {
      'student_id': studentID,
      'role': role,
    });
  }
}

