import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class PromoteUserScreen extends StatefulWidget {
  @override
  _PromoteUserScreenState createState() => _PromoteUserScreenState();
}

class _PromoteUserScreenState extends State<PromoteUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIDController = TextEditingController();
  final _roleController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<String> _roles = ['admin', 'faculty', 'staff', 'student'];

  @override
  void dispose() {
    _studentIDController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _handlePromote() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await _apiService.promoteUser(
          _studentIDController.text.trim(),
          _roleController.text.trim(),
        );

        if (response.statusCode == 200) {
          Fluttertoast.showToast(msg: 'User role updated successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().contains('not found') 
              ? 'User not found'
              : 'Failed to promote user',
          backgroundColor: Colors.red,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Promote User')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Promote User to New Role',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: _studentIDController,
                decoration: InputDecoration(
                  labelText: 'Student ID *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Student ID is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _roleController.text.isEmpty ? null : _roleController.text,
                decoration: InputDecoration(
                  labelText: 'New Role *',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _roleController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Role is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handlePromote,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Promote User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

