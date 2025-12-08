import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
// 'dart:convert' not needed here
import '../../services/api_service.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/qr_code_generator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_button.dart';
import '../../utils/formatters.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final int? eventID;

  MarkAttendanceScreen({this.eventID});

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final ApiService _apiService = ApiService();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  Event? _selectedEvent;
  List<Event> _events = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    if (widget.eventID != null) {
      _loadEvent();
    } else {
      _loadEvents();
    }
  }

  Future<void> _loadEvent() async {
    try {
      final response = await _apiService.getEvent(widget.eventID!);
      if (response.statusCode == 200) {
        setState(() {
          _selectedEvent = Event.fromJson(response.data['event']);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load event');
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final response = await _apiService.getMyEvents();
      if (response.statusCode == 200) {
        setState(() {
          _events = (response.data['events'] as List)
              .map((e) => Event.fromJson(e))
              .toList();
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load events');
      setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _markAttendance(String action) async {
    if (_selectedEvent == null) {
      Fluttertoast.showToast(msg: 'Please select an event');
      return;
    }

    try {
      final response = await _apiService.markAttendance({
        'event_id': _selectedEvent!.id,
        'action': action,
        'method': 'qr_scan',
      });

      if (response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: action == 'check_in' ? 'Checked in successfully!' : 'Checked out successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().contains('already') 
            ? 'You have already ${action == 'check_in' ? 'checked in' : 'checked out'}'
            : 'Failed to mark attendance',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Check if user is admin or superadmin
    if (user == null || (user.role != 'admin' && user.role != 'superadmin')) {
      return Scaffold(
        appBar: AppHeader(title: 'Mark Attendance', showBack: true),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: AppTheme.errorColor),
                SizedBox(height: AppTheme.spacingMD),
                Text('Access Denied', style: AppTheme.heading2),
                SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Only administrators can scan QR codes to mark attendance.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                ),
                SizedBox(height: AppTheme.spacingLG),
                ModernButton(label: 'Go Back', onPressed: () => Navigator.pop(context), primary: true),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppHeader(title: 'Mark Attendance'),
      body: _selectedEvent == null && widget.eventID == null ? _buildEventSelection() : _buildScanner(),
    );
  }

  Widget _buildEventSelection() {
    if (_isLoadingEvents) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Select an event to mark attendance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              return ModernCard(
                child: ListTile(
                  title: Text(event.title, style: AppTheme.heading4),
                  subtitle: Text('${formatDate(event.eventDate)} • ${event.status}', style: AppTheme.bodySmall),
                  trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary),
                  onTap: () => setState(() => _selectedEvent = event),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    final canScan = _canScan();
    final timeRemaining = _getTimeUntilScanAllowed();
    
    return Column(
      children: [
        if (_selectedEvent != null)
          ModernCard(
            margin: EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedEvent!.title, style: AppTheme.heading3),
                SizedBox(height: AppTheme.spacingSM),
                Text('Date: ${formatDate(_selectedEvent!.eventDate)}', style: AppTheme.bodyMedium),
                Text('Time: ${formatTime(_selectedEvent!.startTime)} - ${formatTime(_selectedEvent!.endTime)}', style: AppTheme.bodyMedium),
                SizedBox(height: AppTheme.spacingSM),
                if (!canScan)
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(color: AppTheme.warningColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: AppTheme.warningColor),
                        SizedBox(width: AppTheme.spacingSM),
                        Expanded(child: Text('Scanning will be available in $timeRemaining', style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor)))
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor),
                        SizedBox(width: AppTheme.spacingSM),
                        Expanded(child: Text('Scanning is now available', style: AppTheme.bodySmall.copyWith(color: AppTheme.successColor)))
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              // Show scanner only if scanning is allowed
              if (canScan)
                MobileScanner(
                  controller: _scannerController ??= MobileScannerController(),
                  onDetect: (capture) {
                    if (!_isScanning) {
                      _isScanning = true;
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _handleQRCode(barcode.rawValue!);
                          break;
                        }
                      }
                    }
                  },
                )
              else
                // Show message if scanning is not allowed yet
                Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 64,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Scanning Not Available Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'You can start scanning QR codes $timeRemaining before the event starts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Event starts at: ${_selectedEvent!.startTime.toString().split(' ')[1].substring(0, 5)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (canScan)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scan student QR code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Point camera at student\'s QR code',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Check if scanning is allowed (2 hours before event start)
  bool _canScan() {
    if (_selectedEvent == null) return false;
    
    final now = DateTime.now();
    final twoHoursBeforeEvent = _selectedEvent!.startTime.subtract(Duration(hours: 2));
    
    // Can scan if current time is 2 hours or less before event start
    return now.isAfter(twoHoursBeforeEvent) || now.isAtSameMomentAs(twoHoursBeforeEvent);
  }

  /// Get time remaining until scanning is allowed
  String _getTimeUntilScanAllowed() {
    if (_selectedEvent == null) return '';
    
    final now = DateTime.now();
    final twoHoursBeforeEvent = _selectedEvent!.startTime.subtract(Duration(hours: 2));
    
    if (now.isBefore(twoHoursBeforeEvent)) {
      final difference = twoHoursBeforeEvent.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      
      if (hours > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes != 1 ? 's' : ''}';
      } else {
        return '$minutes minute${minutes != 1 ? 's' : ''}';
      }
    }
    
    return '';
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_selectedEvent == null) {
      Fluttertoast.showToast(msg: 'Please select an event first');
      _isScanning = false;
      return;
    }

    // Check if scanning is allowed (2 hours before event)
    if (!_canScan()) {
      final timeRemaining = _getTimeUntilScanAllowed();
      Fluttertoast.showToast(
        msg: 'Scanning is not allowed yet. You can scan $timeRemaining before the event starts.',
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_LONG,
      );
      _isScanning = false;
      return;
    }

    try {
      // Try to extract student ID from QR code data
      // QR code can contain JSON with all user info or just student ID
      String? studentID = QRCodeGenerator.extractStudentID(qrData);
      
      // If extraction failed, try old format
      if (studentID == null || studentID.isEmpty) {
        if (qrData.startsWith('student:')) {
          final parts = qrData.split(':');
          if (parts.length >= 2) {
            studentID = parts[1];
          }
        } else {
          // Assume it's just the student ID
          studentID = qrData.trim();
        }
      }

      if (studentID == null || studentID.isEmpty) {
        Fluttertoast.showToast(msg: 'Invalid QR code format');
        _isScanning = false;
        return;
      }

      // Fetch student details to get name
      String? studentName;
      try {
        final userResponse = await _apiService.getUserByStudentID(studentID);
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['user'] ?? userResponse.data;
          if (userData != null) {
            final user = User.fromJson(userData);
            studentName = '${user.firstName} ${user.lastName}'.trim();
            if (studentName.isEmpty) {
              studentName = user.username.isNotEmpty ? user.username : studentID;
            }
          }
        }
      } catch (e) {
        // If we can't get user details, try getAllUsers
        try {
          final allUsersResponse = await _apiService.getAllUsers();
          if (allUsersResponse.statusCode == 200) {
            final users = allUsersResponse.data['users'] as List?;
            if (users != null) {
              final userData = users.firstWhere(
                (u) => u['student_id'] == studentID,
                orElse: () => null,
              );
              if (userData != null) {
                final user = User.fromJson(userData);
                studentName = '${user.firstName} ${user.lastName}'.trim();
                if (studentName.isEmpty) {
                  studentName = user.username.isNotEmpty ? user.username : studentID;
                }
              }
            }
          }
        } catch (e2) {
          // If we can't get name, use student ID
          studentName = studentID;
        }
      }

      // If we still don't have a name, use student ID
      if (studentName == null || studentName.isEmpty) {
        studentName = studentID;
      }

      // Check if student already checked in for this event
      String action = 'check_in'; // Default action
      try {
        final attendanceResponse = await _apiService.getAttendanceByEvent(_selectedEvent!.id);
        if (attendanceResponse.statusCode == 200) {
          final attendances = attendanceResponse.data['attendances'] as List?;
          if (attendances != null) {
            // Check if student already has attendance record
            final existingAttendance = attendances.firstWhere(
              (att) => att['student_id'] == studentID,
              orElse: () => null,
            );
            
            if (existingAttendance != null) {
              // Check if already checked in but not checked out
              if (existingAttendance['check_in_time'] != null && 
                  existingAttendance['check_out_time'] == null) {
                // Student already checked in, so this is check out
                action = 'check_out';
              } else if (existingAttendance['check_in_time'] != null && 
                         existingAttendance['check_out_time'] != null) {
                // Already checked in and out, show message
                Fluttertoast.showToast(
                  msg: 'Student already checked in and out',
                  backgroundColor: Colors.orange,
                );
                _isScanning = false;
                return;
              }
            }
          }
        }
      } catch (e) {
        // If we can't check, proceed with check_in
        action = 'check_in';
      }

      // Mark attendance for the scanned student
      final response = await _apiService.markAttendance({
        'event_id': _selectedEvent!.id,
        'student_id': studentID,
        'action': action,
        'method': 'qr_scan',
      });

      if (response.statusCode == 201) {
        final actionText = action == 'check_in' ? 'checked in' : 'checked out';
        
        // Show success dialog with student name
        _showSuccessDialog(studentName, studentID, actionText);
        
        // Reset scanning after a delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isScanning = false);
          }
        });
      } else {
        // If check_in fails with "already checked in", try check_out
        if (response.statusCode != 201 && 
            (response.data['error']?.toString().toLowerCase().contains('already') ?? false) &&
            action == 'check_in') {
          // Try check out instead
          try {
            final checkoutResponse = await _apiService.markAttendance({
              'event_id': _selectedEvent!.id,
              'student_id': studentID,
              'action': 'check_out',
              'method': 'qr_scan',
            });
            
            if (checkoutResponse.statusCode == 201) {
              // Show success dialog with student name
              _showSuccessDialog(studentName, studentID, 'checked out');
              Future.delayed(Duration(seconds: 2), () {
                if (mounted) {
                  setState(() => _isScanning = false);
                }
              });
              return;
            }
          } catch (e) {
            // Fall through to error handling
          }
        }
        
        Fluttertoast.showToast(
          msg: response.data['error'] ?? 'Failed to mark attendance',
          backgroundColor: Colors.red,
        );
        _isScanning = false;
      }
    } catch (e) {
      String errorMsg = 'Failed to mark attendance';
      if (e.toString().contains('already')) {
        // Try check out if already checked in
        try {
          final studentID = QRCodeGenerator.extractStudentID(qrData) ?? 
                           (qrData.startsWith('student:') ? qrData.split(':')[1] : qrData.trim());
          final checkoutResponse = await _apiService.markAttendance({
            'event_id': _selectedEvent!.id,
            'student_id': studentID,
            'action': 'check_out',
            'method': 'qr_scan',
          });
          
          if (checkoutResponse.statusCode == 201) {
            // Try to get student name
            String? name = studentID;
            try {
              final userResponse = await _apiService.getUserByStudentID(studentID);
              if (userResponse.statusCode == 200) {
                final userData = userResponse.data['user'] ?? userResponse.data;
                if (userData != null) {
                  final user = User.fromJson(userData);
                  name = '${user.firstName} ${user.lastName}'.trim();
                  if (name.isEmpty) name = user.username.isNotEmpty ? user.username : studentID;
                }
              }
            } catch (e) {
              name = studentID;
            }
            
            // Show success dialog with student name
            _showSuccessDialog(name, studentID, 'checked out');
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _isScanning = false);
              }
            });
            return;
          }
        } catch (e2) {
          errorMsg = 'Student has already checked in and out';
        }
      } else if (e.toString().contains('not found')) {
        errorMsg = 'Student not found';
      }
      
      Fluttertoast.showToast(
        msg: errorMsg,
        backgroundColor: Colors.red,
      );
      _isScanning = false;
    }
  }

  void _showSuccessDialog(String studentName, String studentID, String action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacingLG),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.successColor.withOpacity(0.1),
                AppTheme.successColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'Success!',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
              SizedBox(height: AppTheme.spacingSM),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: AppTheme.primaryColor),
                        SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Text(
                            studentName,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingXS),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 18, color: AppTheme.textSecondary),
                        SizedBox(width: AppTheme.spacingSM),
                        Text(
                          'ID: $studentID',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacingMD),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: AppTheme.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  '${action.replaceAll('_', ' ').toUpperCase()}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingLG),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXL,
                      vertical: AppTheme.spacingSM,
                    ),
                  ),
                  child: Text('OK', style: AppTheme.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Auto-close after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }
}

