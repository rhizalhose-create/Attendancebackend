// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import '../utils/recaptcha.dart';
import '../widgets/verification_game.dart';
import '../services/api_service.dart';
import 'signup.dart'; // Import the sign up screen
import 'forgot_password.dart'; // Import the forgot password screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F9FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / avatar
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
                  ),
                  child: Image.asset('assets/images/school_logo.png', fit: BoxFit.cover),
                ),
                SizedBox(height: 28),

                // Card
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 480),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _studentIdController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                                hintText: 'Student ID',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => (v==null || v.isEmpty) ? 'Enter student ID' : null,
                            ),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                                hintText: 'Password',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                              validator: (v) {
                                if (v==null || v.isEmpty) return 'Enter password';
                                if (v.length < 6) return 'At least 6 chars';
                                return null;
                              },
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _navigateToForgotPassword(context),
                                child: Text('Forgot Password?', style: TextStyle(color: Colors.blueAccent)),
                              ),
                            ),
                            SizedBox(height: 8),

                            // Login button: shows minigame first, then reCAPTCHA
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  print('[login] Login button pressed');
                                  if (!_formKey.currentState!.validate()) {
                                    print('[login] Form validation failed');
                                    return;
                                  }
                                  
                                  // Step 1: Show minigame first
                                  print('[login] Starting minigame...');
                                  String? gameToken;
                                  try {
                                    final result = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Scaffold(
                                          appBar: AppBar(title: Text('Verification')),
                                          body: VerificationGame(
                                            onVerified: (token) {
                                              Navigator.of(context).pop(token);
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                    gameToken = result;
                                  } catch (e) {
                                    print('[login] Minigame error: $e');
                                    gameToken = null;
                                  }

                                  // If minigame failed, stop here
                                  if (gameToken == null) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Verification game cancelled. Please try again.'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  print('[login] Minigame passed: $gameToken');

                                  // Step 2: After minigame, show reCAPTCHA
                                  /*
                                  String? recaptchaToken;
                                  try {
                                    recaptchaToken = await getRecaptchaToken(context, 'login');
                                  } catch (e) {
                                    recaptchaToken = null;
                                  }

                                  // If reCAPTCHA failed, stop
                                  if (recaptchaToken == null) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('reCAPTCHA verification failed. Please try again.'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  print('[login] reCAPTCHA passed: $recaptchaToken');
                                  */

                                  // Step 3: Both verifications passed, proceed to login
                                  _performLogin(); // token: recaptchaToken);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF26C6DA)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 18),
                TextButton(
                  onPressed: () => _navigateToSignUp(context),
                  child: Text('Don\'t have an account? Sign Up', style: TextStyle(color: Colors.grey[700])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  void _performLogin({String? token}) async {
    print('[login] _performLogin called with token: ${token != null ? 'present' : 'null'}');
    final studentId = _studentIdController.text;
    final password = _passwordController.text;
    print('[login] StudentID: $studentId, Password length: ${password.length}');

    if (studentId.isEmpty || password.isEmpty) {
      print('[login] Empty fields, returning');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    print('[login] Showing loading dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      print('[login] Creating ApiService');
      final apiService = ApiService();
      print('[login] Calling apiService.login');
      final response = await apiService.login(studentId, password, recaptchaToken: token);
      print('[login] API response received: ${response.statusCode}');

      if (mounted) Navigator.of(context).pop(); // Hide loading

      if (response.statusCode == 200) {
        // Login successful
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_id', studentId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen or wherever
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
        print('Login successful for student: $studentId');
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${response.data['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('[login] API call failed with error: $e');
      if (mounted) Navigator.of(context).pop(); // Hide loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToSignUp(BuildContext context) {
    // Navigate to sign up screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpScreen()),
    );
  }

  void _navigateToForgotPassword(BuildContext context) {
    // Navigate to forgot password screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}