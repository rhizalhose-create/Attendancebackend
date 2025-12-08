import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.profilePicture != null && user.profilePicture!.isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: MemoryImage(
                    base64Decode(user.profilePicture!.split(',')[1]),
                  ),
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.person, size: 60),
                ),
              ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Student ID', user.studentID),
                    _buildInfoRow('Email', user.email),
                    _buildInfoRow('Username', user.username),
                    _buildInfoRow('Name', '${user.firstName} ${user.lastName}'),
                    if (user.middleName != null)
                      _buildInfoRow('Middle Name', user.middleName!),
                    _buildInfoRow('Role', user.role.toUpperCase()),
                    _buildInfoRow('Verified', user.isVerified ? 'Yes' : 'No'),
                    if (user.course != null) _buildInfoRow('Course', user.course!),
                    if (user.yearLevel != null) _buildInfoRow('Year Level', user.yearLevel!),
                    if (user.section != null) _buildInfoRow('Section', user.section!),
                    if (user.department != null) _buildInfoRow('Department', user.department!),
                    if (user.college != null) _buildInfoRow('College', user.college!),
                    if (user.contactNumber != null)
                      _buildInfoRow('Contact', user.contactNumber!),
                    if (user.address != null) _buildInfoRow('Address', user.address!),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (user.qrCodeData != null && user.qrCodeData!.isNotEmpty) ...[
              Text(
                'Your QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Center(
                child: _buildQRCodeDisplay(user.qrCodeData!),
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildQRCodeDisplay(String qrCodeData) {
    // Check if it's base64 image data (from database) or QR code string
    if (qrCodeData.startsWith('data:image')) {
      // It's a base64 image from database - decode and display
      try {
        final base64String = qrCodeData.split(',')[1];
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      } catch (e) {
        // If decoding fails, fallback to generating QR code from the string
        return QrImageView(
          data: qrCodeData,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        );
      }
    } else {
      // It's a QR code data string (e.g., "student:STUDENTID" or "event:123:student:STUDENTID")
      // Use QrImageView to generate QR code from the string
      return QrImageView(
        data: qrCodeData,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    }
  }
}

