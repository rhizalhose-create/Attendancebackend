import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'promote_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllUsers();
      if (response.statusCode == 200) {
        setState(() {
          _users = (response.data['users'] as List)
              .map((e) => User.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load users');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final isSuperAdmin = currentUser?.role == 'superadmin';
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppTheme.spacingSM,
                left: AppTheme.spacingMD,
                right: AppTheme.spacingMD,
                bottom: AppTheme.spacingMD,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
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
                      'User Management',
                      style: AppTheme.heading2.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadUsers,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                              SizedBox(height: AppTheme.spacingMD),
                              Text(
                                'No users found',
                                style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              margin: EdgeInsets.all(AppTheme.spacingMD),
                              padding: EdgeInsets.all(AppTheme.spacingMD),
                              decoration: AppTheme.cardDecoration,
                              child: Row(
                                children: [
                                  Icon(Icons.people, color: AppTheme.primaryColor),
                                  SizedBox(width: AppTheme.spacingSM),
                                  Text(
                                    'Total Users: ${_users.length}',
                                    style: AppTheme.heading3,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  final user = _users[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: AppTheme.spacingSM),
                                    decoration: AppTheme.cardDecoration,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingMD,
                                        vertical: AppTheme.spacingSM,
                                      ),
                                      title: Text(
                                        '${user.firstName} ${user.lastName}',
                                        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Padding(
                                        padding: EdgeInsets.only(top: AppTheme.spacingXS),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('ID: ${user.studentID}', style: AppTheme.bodySmall),
                                            Text('Email: ${user.email}', style: AppTheme.bodySmall),
                                            Text('Role: ${user.role}', style: AppTheme.bodySmall),
                                            Text(
                                              'Verified: ${user.isVerified ? 'Yes' : 'No'}',
                                              style: AppTheme.bodySmall,
                                            ),
                                            if (user.course != null)
                                              Text('Course: ${user.course}', style: AppTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Chip(
                                            label: Text(
                                              user.role.toUpperCase(),
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor: _getRoleColor(user.role),
                                            padding: EdgeInsets.symmetric(horizontal: 6),
                                          ),
                                          // Only show promote button for superadmin
                                          if (isSuperAdmin)
                                            IconButton(
                                              icon: Icon(Icons.edit, size: 18),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PromoteUserScreen(),
                                                  ),
                                                ).then((_) => _loadUsers());
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'superadmin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'faculty':
        return Colors.blue;
      case 'staff':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

