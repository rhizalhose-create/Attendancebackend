import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/qr_code_dialog.dart';
import '../../utils/qr_code_generator.dart';
import '../events/events_list_screen.dart';
import '../events/create_event_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/promote_user_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/logout_confirmation_dialog.dart';

class SuperAdminDashboard extends StatefulWidget {
  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    _HomeTab(),
    EventsListScreen(),
    UserManagementScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SuperAdmin Dashboard',
                          style: AppTheme.heading3.copyWith(color: Colors.white),
                        ),
                        if (user != null)
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      final confirm = await showLogoutConfirmationDialog(context);
                      if (confirm == true) {
                        await authProvider.logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: FloatingActionButton(
              heroTag: 'create_event',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventScreen()),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
          SizedBox(height: AppTheme.spacingMD),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.secondaryColor, AppTheme.accentColor],
              ),
              shape: BoxShape.circle,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: FloatingActionButton(
              heroTag: 'promote_user',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PromoteUserScreen()),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(Icons.person_add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacingLG),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingSM),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.firstName ?? 'SuperAdmin'}!',
                            style: AppTheme.heading2,
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            'Role: ${user?.role?.toUpperCase() ?? 'SUPERADMIN'}',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingLG),
          Text(
            'Quick Actions',
            style: AppTheme.heading3,
          ),
          SizedBox(height: AppTheme.spacingMD),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppTheme.spacingMD,
            mainAxisSpacing: AppTheme.spacingMD,
            children: [
              _buildActionCard(
                context,
                icon: Icons.qr_code,
                title: 'My QR Code',
                color: AppTheme.primaryColor,
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  var user = authProvider.user;
                  
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User not found. Please login again.')),
                    );
                    return;
                  }
                  
                  // If qrCodeData is not available, try to refresh user profile
                  if (user.qrCodeData == null || user.qrCodeData!.isEmpty) {
                    await authProvider.refreshUserProfile();
                    user = authProvider.user;
                  }
                  
                  String qrDataToShow = '';
                  
                  if (user != null && user.qrCodeData != null && user.qrCodeData!.isNotEmpty) {
                    // Use QR data from database
                    qrDataToShow = user.qrCodeData!;
                  } else if (user != null) {
                    // Generate QR code with all user information
                    qrDataToShow = QRCodeGenerator.generateUserQRData(user);
                  }
                  
                  if (qrDataToShow.isNotEmpty) {
                    // Show QR code dialog
                    QRCodeDialog.show(context, qrDataToShow, title: 'My QR Code');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to generate QR code. Please contact administrator.')),
                    );
                  }
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.add_circle,
                title: 'Create Event',
                color: AppTheme.successColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateEventScreen()),
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.people,
                title: 'Manage Users',
                color: AppTheme.warningColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserManagementScreen()),
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.person_add,
                title: 'Promote User',
                color: AppTheme.accentColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PromoteUserScreen()),
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.event,
                title: 'View Events',
                color: AppTheme.secondaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventsListScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                SizedBox(height: AppTheme.spacingMD),
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
