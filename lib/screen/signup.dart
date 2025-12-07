// lib/screens/signup.dart
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _courseController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _sectionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // For dropdowns
  String? _selectedCourse;
  String? _selectedYearLevel;
  
  // Sample data for dropdowns
  final List<String> _courses = [
    'Bachelor of Science in Computer Science',
    'Bachelor of Science in Information Technology',
    'Bachelor of Science in Computer Engineering',
    'Bachelor of Science in Electronics Engineering',
    'Bachelor of Science in Civil Engineering',
    'Bachelor of Science in Mechanical Engineering',
    'Bachelor of Science in Electrical Engineering',
    'Bachelor of Science in Accountancy',
    'Bachelor of Science in Business Administration',
    'Bachelor of Science in Nursing',
    'Bachelor of Science in Education',
  ];
  
  final List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // New Account Title
                  Center(
                    child: Text(
                      'New Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Personal Info Section
                  _buildSectionHeader('Personal Info'),
                  SizedBox(height: 16),

                  // First Name and Last Name in one row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('First Name:'),
                            SizedBox(height: 4),
                            _buildTextField(_firstNameController, hint: 'Enter first name'),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Last Name:'),
                            SizedBox(height: 4),
                            _buildTextField(_lastNameController, hint: 'Enter last name'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Middle Name
                  _buildFieldLabel('Middle Name:'),
                  SizedBox(height: 4),
                  _buildTextField(_middleNameController, hint: 'Enter middle name'),
                  SizedBox(height: 16),

                  // Contact No.
                  _buildFieldLabel('Contact No.:'),
                  SizedBox(height: 4),
                  _buildTextField(_contactNoController, hint: 'Enter contact number', keyboardType: TextInputType.phone),
                  SizedBox(height: 16),

                  // Address
                  _buildFieldLabel('Address:'),
                  SizedBox(height: 4),
                  _buildTextField(_addressController, hint: 'Enter address', maxLines: 2),
                  SizedBox(height: 24),

                  // Academic Info Section
                  _buildSectionHeader('Academic Info'),
                  SizedBox(height: 16),

                  // Course Dropdown
                  _buildFieldLabel('Course:'),
                  SizedBox(height: 4),
                  _buildCourseDropdown(),
                  SizedBox(height: 16),

                  // Year Level Dropdown (added)
                  _buildFieldLabel('Year Level:'),
                  SizedBox(height: 4),
                  _buildYearLevelDropdown(),
                  SizedBox(height: 16),

                  // Your College
                  _buildFieldLabel('College:', isBold: true),
                  SizedBox(height: 4),
                  _buildTextField(_collegeController, hint: 'Enter college'),
                  SizedBox(height: 16),

                  // Department and Section in one row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Department:', isBold: true),
                            SizedBox(height: 4),
                            _buildTextField(_departmentController, hint: 'Enter department'),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Section:', isBold: true),
                            SizedBox(height: 4),
                            _buildTextField(_sectionController, hint: 'Enter section'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Account Info Section
                  _buildSectionHeader('Account Info'),
                  SizedBox(height: 16),

                  // Email
                  _buildFieldLabel('Email:'),
                  SizedBox(height: 4),
                  _buildTextField(_emailController, hint: 'Enter email', keyboardType: TextInputType.emailAddress),
                  SizedBox(height: 16),

                  // Password
                  _buildFieldLabel('Password:'),
                  SizedBox(height: 4),
                  _buildPasswordField(_passwordController, hint: 'Enter password', isPassword: true),
                  SizedBox(height: 16),

                  // Confirm Password
                  _buildFieldLabel('Confirm Password:'),
                  SizedBox(height: 4),
                  _buildPasswordField(_confirmPasswordController, hint: 'Confirm password', isPassword: false),
                  SizedBox(height: 32),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _performSignUp();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Already have account link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _navigateToLogin(context),
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isBold = false}) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCourse,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        hint: Text('Select your course'),
      ),
      items: _courses.map((String course) {
        return DropdownMenuItem<String>(
          value: course,
          child: Text(
            course,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCourse = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your course';
        }
        return null;
      },
      isExpanded: true,
    );
  }

  Widget _buildYearLevelDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedYearLevel,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        hint: Text('Select your year level'),
      ),
      items: _yearLevels.map((String year) {
        return DropdownMenuItem<String>(
          value: year,
          child: Text(year),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedYearLevel = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your year level';
        }
        return null;
      },
      isExpanded: true,
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller, {
    String hint = '',
    required bool isPassword,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: Icon(
            (isPassword ? _isPasswordVisible : _isConfirmPasswordVisible)
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              if (isPassword) {
                _isPasswordVisible = !_isPasswordVisible;
              } else {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              }
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (isPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (!isPassword && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  void _performSignUp() {
    // Implement sign up logic here
    print('Signing up...');
    print('Selected Course: $_selectedCourse');
    print('Selected Year Level: $_selectedYearLevel');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    // Navigate back to login screen
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _contactNoController.dispose();
    _addressController.dispose();
    _courseController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _sectionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}