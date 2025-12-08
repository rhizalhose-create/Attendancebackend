import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String studentID, String password, {String? recaptchaToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(studentID, password, recaptchaToken: recaptchaToken);
      
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_id', studentID);
        
        // Extract role from login response (priority: use role from backend)
        String? roleFromResponse;
        Map<String, dynamic>? userDataFromResponse;
        
        if (response.data != null) {
          // Check if response has user object
          if (response.data['user'] != null) {
            userDataFromResponse = response.data['user'] is Map 
                ? Map<String, dynamic>.from(response.data['user']) 
                : null;
            if (userDataFromResponse != null && userDataFromResponse['role'] != null) {
              roleFromResponse = userDataFromResponse['role'].toString().toLowerCase().trim();
            }
          } else if (response.data['role'] != null) {
            roleFromResponse = response.data['role'].toString().toLowerCase().trim();
          }
        }
        
        // Try to fetch full user details (this should include role)
        try {
          await fetchUserDetails(studentID);
        } catch (e) {
          // fetchUserDetails failed, will use role from response
        }
        
        // ALWAYS use role from login response if available, even if fetchUserDetails succeeded
        // This ensures we use the correct role from the database
        if (roleFromResponse != null && roleFromResponse.isNotEmpty) {
          // If we have role from response, use it (especially if fetchUserDetails returned 'student')
          if (_user == null || _user!.role.toLowerCase() != roleFromResponse) {
            // Use role from login response
            if (userDataFromResponse != null) {
              // Use full user data from response if available
              _user = User.fromJson(userDataFromResponse);
              // Ensure role is set correctly
              if (_user!.role.toLowerCase() != roleFromResponse) {
                final currentUser = _user!;
                _user = User(
                  studentID: currentUser.studentID,
                  email: currentUser.email,
                  username: currentUser.username,
                  firstName: currentUser.firstName,
                  lastName: currentUser.lastName,
                  middleName: currentUser.middleName,
                  course: currentUser.course,
                  yearLevel: currentUser.yearLevel,
                  section: currentUser.section,
                  department: currentUser.department,
                  college: currentUser.college,
                  contactNumber: currentUser.contactNumber,
                  address: currentUser.address,
                  role: roleFromResponse, // Use role from login response
                  isVerified: currentUser.isVerified,
                  qrCodeData: currentUser.qrCodeData,
                  profilePicture: currentUser.profilePicture,
                  createdAt: currentUser.createdAt,
                  verifiedAt: currentUser.verifiedAt,
                );
              }
            } else if (_user != null) {
              // Update existing user with role from response
              final currentUser = _user!;
              _user = User(
                studentID: currentUser.studentID,
                email: currentUser.email,
                username: currentUser.username,
                firstName: currentUser.firstName,
                lastName: currentUser.lastName,
                middleName: currentUser.middleName,
                course: currentUser.course,
                yearLevel: currentUser.yearLevel,
                section: currentUser.section,
                department: currentUser.department,
                college: currentUser.college,
                contactNumber: currentUser.contactNumber,
                address: currentUser.address,
                role: roleFromResponse, // Use role from login response
                isVerified: currentUser.isVerified,
                qrCodeData: currentUser.qrCodeData,
                profilePicture: currentUser.profilePicture,
                createdAt: currentUser.createdAt,
                verifiedAt: currentUser.verifiedAt,
              );
            } else {
              // Create new user with role from response
              _user = User(
                studentID: response.data['student_id'] ?? studentID,
                email: response.data['email'] ?? '',
                username: response.data['username'] ?? '',
                firstName: response.data['first_name'] ?? '',
                lastName: response.data['last_name'] ?? '',
                role: roleFromResponse, // Use role from login response
                isVerified: response.data['is_verified'] ?? true,
                createdAt: DateTime.now(),
              );
            }
          }
        }
        
        // Final check: if user exists but role is 'student' and we have role from response, update it
        if (_user != null && roleFromResponse != null && roleFromResponse.isNotEmpty) {
          if (_user!.role.toLowerCase() == 'student' && roleFromResponse != 'student') {
            // Force update role from response
            final currentUser = _user!;
            _user = User(
              studentID: currentUser.studentID,
              email: currentUser.email,
              username: currentUser.username,
              firstName: currentUser.firstName,
              lastName: currentUser.lastName,
              middleName: currentUser.middleName,
              course: currentUser.course,
              yearLevel: currentUser.yearLevel,
              section: currentUser.section,
              department: currentUser.department,
              college: currentUser.college,
              contactNumber: currentUser.contactNumber,
              address: currentUser.address,
              role: roleFromResponse, // Force use role from login response
              isVerified: currentUser.isVerified,
              qrCodeData: currentUser.qrCodeData,
              profilePicture: currentUser.profilePicture,
              createdAt: currentUser.createdAt,
              verifiedAt: currentUser.verifiedAt,
            );
          }
        }
        
        // If no user was created at all, create a basic one
        if (_user == null) {
          _user = User(
            studentID: studentID,
            email: '',
            username: '',
            firstName: '',
            lastName: '',
            role: roleFromResponse ?? 'student', // Use role from response or default
            isVerified: true,
            createdAt: DateTime.now(),
          );
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('error')) {
            _error = errorData['error'] as String;
          } else {
            // Check status code for specific errors
            switch (e.response?.statusCode) {
              case 400:
                _error = 'Invalid credentials. Please check your Student ID and password.';
                break;
              case 401:
                _error = 'Unauthorized. Please check your credentials.';
                break;
              case 403:
                _error = 'Account not verified. Please verify your email first.';
                break;
              default:
                _error = 'Invalid credentials';
            }
          }
        } else {
          // Network error
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            _error = 'Connection timeout. Please check:\n1. Backend server is running\n2. Phone and computer on same Wi-Fi\n3. Firewall allows port 3000';
          } else if (e.type == DioExceptionType.connectionError) {
            _error = 'Cannot connect to server.\n\nPlease check:\n1. Backend server is running on port 3000\n2. Backend listens on 0.0.0.0:3000 (not localhost)\n3. Phone and computer on same Wi-Fi network\n4. Firewall allows port 3000\n5. IP address in api_service.dart is correct\n\nSee BACKEND_CONNECTION_GUIDE.md for details.';
          } else {
            _error = 'Network error. Please check your connection and backend server.';
          }
        }
      } else {
        _error = 'Login failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginByEmail(String email, String password, {String? recaptchaToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.loginByEmailWithToken(email, password, recaptchaToken: recaptchaToken);
      
      if (response.statusCode == 200) {
        // For email login, we need to fetch user details first
        await fetchUserByEmail(email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('error')) {
            _error = errorData['error'] as String;
          } else {
            _error = 'Invalid credentials';
          }
        } else {
          // Network error
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            _error = 'Connection timeout. Please check:\n1. Backend server is running\n2. Phone and computer on same Wi-Fi\n3. Firewall allows port 3000';
          } else if (e.type == DioExceptionType.connectionError) {
            _error = 'Cannot connect to server.\n\nPlease check:\n1. Backend server is running on port 3000\n2. Backend listens on 0.0.0.0:3000 (not localhost)\n3. Phone and computer on same Wi-Fi network\n4. Firewall allows port 3000\n5. IP address in api_service.dart is correct\n\nSee BACKEND_CONNECTION_GUIDE.md for details.';
          } else {
            _error = 'Network error. Please check your connection and backend server.';
          }
        }
      } else {
        _error = 'Login failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserDetails(String studentID) async {
    try {
      // Try multiple methods to get user details
      // Method 1: Try getCurrentUser endpoint (best for any authenticated user)
      try {
        final response = await _apiService.getCurrentUser();
        if (response.statusCode == 200) {
          final userData = response.data['user'] ?? response.data;
          if (userData != null) {
            _user = User.fromJson(userData);
            // Ensure role is set correctly
            if (_user!.role.isEmpty || _user!.role == 'student') {
              // If role is missing or default, try other methods
            } else {
              notifyListeners();
              return;
            }
          }
        }
      } catch (e) {
        // getCurrentUser might not exist, try other methods
      }

      // Method 2: Try getUserByStudentID endpoint (for admin/superadmin)
      try {
        final response = await _apiService.getUserByStudentID(studentID);
        if (response.statusCode == 200) {
          final userData = response.data['user'] ?? response.data;
          if (userData != null) {
            _user = User.fromJson(userData);
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        // getUserByStudentID might not exist or require admin, try other methods
      }

      // Method 3: Try to get user details from admin endpoint (requires admin/superadmin)
      try {
        final response = await _apiService.getAllUsers();
        if (response.statusCode == 200) {
          final users = response.data['users'] as List;
          final userData = users.firstWhere(
            (u) => u['student_id'] == studentID,
            orElse: () => null,
          );
          if (userData != null) {
            _user = User.fromJson(userData);
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        // getAllUsers might fail if user is not admin/superadmin, that's okay
      }
      
      // If we can't get user details, don't create a default user here
      // Let the caller handle it with role from login response
      // This prevents overwriting a correct role with 'student'
    } catch (e) {
      // If all fails, don't create default user - let caller handle it
      // This ensures role from login response is preserved
    }
  }

  Future<void> refreshUserProfile() async {
    if (_user == null) return;
    
    try {
      // Try to refresh user data with qrCodeData
      await fetchUserDetails(_user!.studentID);
    } catch (e) {
      // If refresh fails, keep existing user data
    }
  }

  Future<void> fetchUserByEmail(String email) async {
    try {
      // Try getCurrentUser first if available
      try {
        final response = await _apiService.getCurrentUser();
        if (response.statusCode == 200) {
          final userData = response.data['user'] ?? response.data;
          if (userData != null && userData['email'] == email) {
            _user = User.fromJson(userData);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('student_id', _user!.studentID);
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        // getCurrentUser might not exist, try other methods
      }

      // Fallback to getAllUsers
      final response = await _apiService.getAllUsers();
      if (response.statusCode == 200) {
        final users = response.data['users'] as List;
        final userData = users.firstWhere(
          (u) => u['email'] == email,
          orElse: () => null,
        );
        if (userData != null) {
          _user = User.fromJson(userData);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_id', _user!.studentID);
          notifyListeners();
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(data);
      
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Handle DioException to extract user-friendly error messages
      if (e is DioException) {
        if (e.response != null) {
          // Extract error message from response
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('error')) {
            _error = errorData['error'] as String;
          } else {
            // Handle different status codes
            switch (e.response?.statusCode) {
              case 409:
                _error = 'Email or Student ID already exists. Please use a different one.';
                break;
              case 400:
                _error = 'Invalid registration data. Please check your input.';
                break;
              default:
                _error = 'Registration failed. Please try again.';
            }
          }
        } else {
          _error = 'Network error. Please check your connection and try again.';
        }
      } else {
        _error = 'Registration failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyEmail(email, code);
      
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['error'] ?? 'Verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('error')) {
            _error = errorData['error'] as String;
          } else {
            _error = 'Invalid verification code or email';
          }
        } else {
          _error = 'Network error. Please check your connection.';
        }
      } else {
        _error = 'Verification failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_id');
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final studentID = prefs.getString('student_id');
    if (studentID != null && studentID.isNotEmpty) {
      try {
        await fetchUserDetails(studentID);
        // If fetchUserDetails didn't set a user or role is still 'student', 
        // try getCurrentUser as a fallback
        if (_user == null || (_user!.role.isEmpty || _user!.role.toLowerCase() == 'student')) {
          try {
            final response = await _apiService.getCurrentUser();
            if (response.statusCode == 200) {
              final userData = response.data['user'] ?? response.data;
              if (userData != null) {
                _user = User.fromJson(userData);
                notifyListeners();
              }
            }
          } catch (e) {
            // getCurrentUser might not be available, that's okay
          }
        }
      } catch (e) {
        // If all methods fail, user will need to login again
        _user = null;
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

