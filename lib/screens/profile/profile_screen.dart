import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import '../../widgets/app_header.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppHeader(title: 'Profile'),
        body: Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      appBar: AppHeader(title: 'Profile'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: user.profilePicture != null && user.profilePicture!.isNotEmpty
                  ? CircleAvatar(
                      radius: 64,
                      backgroundImage: MemoryImage(base64Decode(user.profilePicture!.split(',')[1])),
                    )
                  : CircleAvatar(
                      radius: 64,
                      child: Icon(Icons.person, size: 64),
                    ),
            ),
            SizedBox(height: AppTheme.spacingLG),

            ModernCard(
              padding: EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.firstName} ${user.lastName}', style: AppTheme.heading4),
                  SizedBox(height: AppTheme.spacingSM),
                  Text(user.email, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
                  SizedBox(height: AppTheme.spacingMD),
                  _buildInfoRow(context, 'Student ID', user.studentID),
                  _buildInfoRow(context, 'Username', user.username),
                  if (user.middleName != null) _buildInfoRow(context, 'Middle Name', user.middleName!),
                  _buildInfoRow(context, 'Role', user.role.toUpperCase()),
                  _buildInfoRow(context, 'Verified', user.isVerified ? 'Yes' : 'No'),
                  if (user.course != null) _buildInfoRow(context, 'Course', user.course!),
                  if (user.yearLevel != null) _buildInfoRow(context, 'Year Level', user.yearLevel!),
                  if (user.section != null) _buildInfoRow(context, 'Section', user.section!),
                  if (user.department != null) _buildInfoRow(context, 'Department', user.department!),
                  if (user.college != null) _buildInfoRow(context, 'College', user.college!),
                  if (user.contactNumber != null) _buildInfoRow(context, 'Contact', user.contactNumber!),
                  if (user.address != null) _buildInfoRow(context, 'Address', user.address!),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingLG),

            if (user.qrCodeData != null && user.qrCodeData!.isNotEmpty) ...[
              Text('Your QR Code', style: AppTheme.heading5),
              SizedBox(height: AppTheme.spacingMD),
              Center(child: _buildQRCodeDisplay(context, user.qrCodeData!)),
            ],

            SizedBox(height: AppTheme.spacingLG),

            Center(
              child: ModernButton(
                label: 'Logout',
                icon: Icons.logout,
                onPressed: () async {
                  final confirm = await showLogoutConfirmationDialog(context);
                  if (confirm == true) {
                    await authProvider.logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label',
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: AppTheme.bodyMedium,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: Icon(Icons.copy, size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeDisplay(BuildContext context, String qrCodeData) {
    // Display the QR inside a card with actions (copy)
    Widget qrWidget;
    if (qrCodeData.startsWith('data:image')) {
      try {
        final base64String = qrCodeData.split(',')[1];
        final imageBytes = base64Decode(base64String);
        qrWidget = Image.memory(
          imageBytes,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        );
      } catch (e) {
        qrWidget = QrImageView(
          data: qrCodeData,
          version: QrVersions.auto,
          size: 220.0,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        );
      }
    } else {
      qrWidget = QrImageView(
        data: qrCodeData,
        version: QrVersions.auto,
        size: 220.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    }

    return ModernCard(
      padding: EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          qrWidget,
          SizedBox(height: AppTheme.spacingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ModernButton(
                label: 'Copy Data',
                outline: true,
                primary: false,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrCodeData));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR data copied')));
                },
              ),
              SizedBox(width: AppTheme.spacingMD),
              ModernButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

