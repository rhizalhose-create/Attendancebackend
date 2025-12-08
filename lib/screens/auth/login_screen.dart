import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../dashboard/student_dashboard.dart';
import '../dashboard/admin_dashboard.dart';
import '../dashboard/superadmin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIDController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _studentIDController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _studentIDController.text.trim(),
        _passwordController.text,
      );

      if (success && authProvider.user != null) {
        final user = authProvider.user!;
        
        // Navigate based on role (case-insensitive check)
        final role = user.role.toLowerCase().trim();
        if (role == 'superadmin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SuperAdminDashboard()),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentDashboard()),
          );
        }
        
        Fluttertoast.showToast(
          msg: 'Login successful!',
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        Fluttertoast.showToast(
          msg: authProvider.error ?? 'Login failed',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG, vertical: AppTheme.spacingXXL),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.elevatedShadow,
                      ),
                      child: Icon(
                        Icons.access_time,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXXL),
                    // Card
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingLG),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _studentIDController,
                            decoration: AppTheme.inputDecoration(
                              label: 'Student ID',
                              hint: 'enter your student id',
                              prefixIcon: Icons.person,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Student ID is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppTheme.spacingMD),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: AppTheme.inputDecoration(
                              label: 'Password',
                              prefixIcon: Icons.lock,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppTheme.spacingSM),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor),
                              ),
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingLG),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.buttonGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                                  ),
                                  child: authProvider.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text('Log In', style: AppTheme.buttonText),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingLG),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterScreen()),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
