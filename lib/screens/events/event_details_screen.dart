import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../attendance/mark_attendance_screen.dart';
import '../attendance/event_attendance_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  EventDetailsScreen({required this.event});

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ApiService _apiService = ApiService();
  Event? _event;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  // Check if description should be shown (only from day before event start date)
  bool _shouldShowDescription(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final dayBeforeEvent = eventDay.subtract(Duration(days: 1));
    
    // Show description if today is >= day before event
    return today.isAfter(dayBeforeEvent) || today.isAtSameMomentAs(dayBeforeEvent);
  }

  Future<void> _loadEventDetails() async {
    try {
      final response = await _apiService.getEvent(widget.event.id);
      if (response.statusCode == 200) {
        setState(() {
          _event = Event.fromJson(response.data['event']);
        });
      }
    } catch (e) {
      // Handle error
    }
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
      // It's a QR code data string - use QrImageView to generate
      return QrImageView(
        data: qrCodeData,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event ?? widget.event;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAdmin = user != null && (user.role == 'admin' || user.role == 'superadmin');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Column(
          children: [
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
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTheme.heading3.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingMD),
                child: Container(
                  padding: EdgeInsets.all(AppTheme.spacingLG),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: AppTheme.heading2,
                      ),
                      SizedBox(height: AppTheme.spacingMD),
                      // Only show description if current date is >= (event_date - 1 day)
                      if (event.description != null && _shouldShowDescription(event.eventDate)) ...[
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingMD),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: AppTheme.spacingXS),
                              Text(
                                event.description!,
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                      ],
                      _buildInfoCard(Icons.calendar_today, 'Date', DateFormat('MMM dd, yyyy').format(event.eventDate)),
                      _buildInfoCard(Icons.access_time, 'Time', 
                        '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
                      if (event.location != null)
                        _buildInfoCard(Icons.location_on, 'Location', event.location!),
                      if (event.course != null)
                        _buildInfoCard(Icons.school, 'Course', event.course!),
                      if (event.section != null)
                        _buildInfoCard(Icons.group, 'Section', event.section!),
                      if (event.yearLevel != null)
                        _buildInfoCard(Icons.calendar_today, 'Year Level', event.yearLevel!),
                      _buildInfoCard(Icons.info, 'Status', event.status.toUpperCase()),
                      SizedBox(height: AppTheme.spacingLG),
                      if (event.qrCodeData != null && event.qrCodeData!.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingMD),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Event QR Code',
                                style: AppTheme.heading3,
                              ),
                              SizedBox(height: AppTheme.spacingMD),
                              _buildQRCodeDisplay(event.qrCodeData!),
                            ],
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingLG),
                      ],
                      // Only show Mark Attendance button for admin and superadmin
                      if (isAdmin)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.buttonGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MarkAttendanceScreen(eventID: event.id),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                                  label: Text('Scan QR Code', style: AppTheme.buttonText),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventAttendanceScreen(eventID: event.id),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.people, color: AppTheme.primaryColor),
                                  label: Text(
                                    'View Attendance',
                                    style: AppTheme.buttonText.copyWith(color: AppTheme.primaryColor),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // For students, only show View Attendance button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventAttendanceScreen(eventID: event.id),
                                ),
                              );
                            },
                            icon: Icon(Icons.people, color: AppTheme.primaryColor),
                            label: Text(
                              'View Attendance',
                              style: AppTheme.buttonText.copyWith(color: AppTheme.primaryColor),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMD),
      padding: EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacingSM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
