import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;

  VerifyEmailScreen({this.email});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _codeControllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final code = _getCode();
    if (code.length != 6) {
      Fluttertoast.showToast(
        msg: 'Please enter the complete 6-digit code',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (widget.email == null) {
      Fluttertoast.showToast(
        msg: 'Email is required',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyEmail(widget.email!, code);

    setState(() => _isLoading = false);

    if (success) {
      Fluttertoast.showToast(
        msg: 'Email verified successfully!',
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Fluttertoast.showToast(
        msg: authProvider.error ?? 'Verification failed',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _resendCode() async {
    if (widget.email == null) return;
    
    try {
      // You might want to add a resend code endpoint
      Fluttertoast.showToast(
        msg: 'Code resent to ${widget.email}',
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to resend code',
        backgroundColor: Colors.red,
      );
    }
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
                        'Verify Email',
                        style: AppTheme.heading3.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppTheme.spacingLG),
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacingLG),
                      decoration: AppTheme.cardDecoration,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verify Your Email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'We Sent A 6 Digit Code To Your Email Address.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    if (widget.email != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 20, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verification sent to: ${widget.email}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),
                    Text(
                      'Enter code:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45,
                          height: 45,
                          child: TextFormField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
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
                                borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) => _onCodeChanged(index, value),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Verify Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
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
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't Receive code? ",
              style: TextStyle(color: Colors.grey[700]),
            ),
            TextButton(
              onPressed: _resendCode,
              child: Text(
                'Re-send code',
                style: TextStyle(
                  color: Color(0xFF2196F3),
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
