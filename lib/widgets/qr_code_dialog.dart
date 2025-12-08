import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';

class QRCodeDialog extends StatelessWidget {
  final String qrCodeData;
  final String? title;

  QRCodeDialog({
    required this.qrCodeData,
    this.title,
  });

  static void show(BuildContext context, String qrCodeData, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(
        qrCodeData: qrCodeData,
        title: title ?? 'My QR Code',
      ),
    );
  }

  Widget _buildQRCodeDisplay(String qrCodeData) {
    // Validate input
    if (qrCodeData.isEmpty) {
      return Container(
        width: 250,
        height: 250,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 8),
              Text('QR code data is empty'),
            ],
          ),
        ),
      );
    }

    // Trim whitespace
    final trimmedData = qrCodeData.trim();
    
    if (trimmedData.isEmpty) {
      return Container(
        width: 250,
        height: 250,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 8),
              Text('QR code data is empty'),
            ],
          ),
        ),
      );
    }
    
    // Check if it's base64 image data (from database) or QR code string
    if (trimmedData.startsWith('data:image')) {
      // It's a base64 image from database - decode and display
      try {
        final base64String = trimmedData.split(',')[1];
        if (base64String.isEmpty) {
          throw Exception('Empty base64 string');
        }
        final imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        );
      } catch (e) {
        // If decoding fails, fallback to generating QR code from the string
        // Use the whole trimmed data
        return QrImageView(
          data: trimmedData,
          version: QrVersions.auto,
          size: 250.0,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          padding: EdgeInsets.all(8),
        );
      }
    } else {
      // It's a QR code data string (e.g., JSON or "student:STUDENTID")
      // Use QrImageView to generate QR code from the string
      // QR codes can handle up to ~3000 characters, but we'll limit to 2000 for safety
      final dataToEncode = trimmedData.length > 2000 
          ? trimmedData.substring(0, 2000) 
          : trimmedData;
      
      return QrImageView(
        data: dataToEncode,
        version: QrVersions.auto,
        size: 250.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        padding: EdgeInsets.all(8),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          gradient: AppTheme.primaryGradient,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? 'My QR Code',
                  style: AppTheme.heading2.copyWith(color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.cardShadow,
              ),
              child: _buildQRCodeDisplay(qrCodeData),
            ),
            SizedBox(height: AppTheme.spacingMD),
            Text(
              'Show this QR code to scan',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingMD),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: AppTheme.buttonText.copyWith(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

