import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
// import '../../utils/recaptcha.dart';
import '../../utils/courses.dart';
import '../../theme/app_theme.dart';
import '../../utils/password_utils.dart';
import '../../widgets/password_strength_indicator.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _sectionController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _selectedCourse;
  String? _selectedYearLevel;
  PasswordStrength _passwordStrength = PasswordStrength.veryWeak;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        Fluttertoast.showToast(
          msg: 'Passwords do not match',
          backgroundColor: Colors.red,
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final data = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'username': _emailController.text.trim().split('@')[0],
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        if (_middleNameController.text.isNotEmpty) 'middle_name': _middleNameController.text.trim(),
        if (_contactNumberController.text.isNotEmpty) 'contact_number': _contactNumberController.text.trim(),
        if (_addressController.text.isNotEmpty) 'address': _addressController.text.trim(),
        if (_selectedCourse != null && _selectedCourse!.isNotEmpty) 'course': _selectedCourse!,
        if (_selectedYearLevel != null && _selectedYearLevel!.isNotEmpty) 'year_level': _selectedYearLevel!,
        if (_collegeController.text.isNotEmpty) 'college': _collegeController.text.trim(),
        if (_departmentController.text.isNotEmpty) 'department': _departmentController.text.trim(),
        if (_sectionController.text.isNotEmpty) 'section': _sectionController.text.trim(),
      };

      // Show blocking dialog while obtaining reCAPTCHA token
      /*
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Expanded(child: Text('Verifying reCAPTCHA...')),
            ],
          ),
        ),
      );

      String? token;
      try {
        token = await getRecaptchaToken(context, 'register');
      } catch (e) {
        token = null;
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (token == null) {
        Fluttertoast.showToast(msg: 'reCAPTCHA verification failed. Please try again.', backgroundColor: Colors.red);
        return;
      }

      // Attach token to payload
      data['recaptcha_token'] = token;
      */

      final success = await authProvider.register(data);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Registration successful! Please verify your email.',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: authProvider.error ?? 'Registration failed',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF2196F3), size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
        SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'New Account',
                        style: AppTheme.heading3.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacingLG),
                      decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personal Info Section
                  _buildSection(
                    'Personal Info',
                    Icons.person,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name:',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name:',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _middleNameController,
                        decoration: AppTheme.inputDecoration(
                          label: 'Middle Name:',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingMD),
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: AppTheme.inputDecoration(
                          label: 'Contact No.:',
                          prefixIcon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: AppTheme.spacingMD),
                      TextFormField(
                        controller: _addressController,
                        decoration: AppTheme.inputDecoration(
                          label: 'Address:',
                          prefixIcon: Icons.home,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                  // Academic Info Section
                  _buildSection(
                    'Academic Info',
                    Icons.school,
                    [
                      DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        decoration: InputDecoration(
                          labelText: 'Course:',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: Courses.courseList.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourse = value;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedYearLevel,
                              decoration: InputDecoration(
                                labelText: 'Year:',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: Courses.yearLevels.map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedYearLevel = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _collegeController,
                              decoration: InputDecoration(
                                labelText: 'College:',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                labelText: 'Department:',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sectionController,
                              decoration: InputDecoration(
                                labelText: 'Section:',
                                prefixIcon: Icon(Icons.group),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Account Info Section
                  _buildSection(
                    'Account Info',
                    Icons.lock,
                    [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email:',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (!value.contains('@')) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        onChanged: (v) {
                          setState(() {
                            _passwordStrength = PasswordUtils.estimate(v);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Password:',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _isPasswordVisible = !_isPasswordVisible);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value.length < 8) {
                            return 'Min 8 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      PasswordStrengthIndicator(strength: _passwordStrength),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password:',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                      SizedBox(height: AppTheme.spacingMD),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.buttonGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _handleRegister,
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
                                  : Text('Sign Up', style: AppTheme.buttonText),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Log In',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
