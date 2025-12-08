import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/modern_card.dart';
import '../../utils/formatters.dart';
import '../../theme/app_theme.dart';

class EventAttendanceScreen extends StatefulWidget {
  final int eventID;

  EventAttendanceScreen({required this.eventID});

  @override
  _EventAttendanceScreenState createState() => _EventAttendanceScreenState();
}

class _EventAttendanceScreenState extends State<EventAttendanceScreen> {
  final ApiService _apiService = ApiService();
  List<Attendance> _attendances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAttendanceByEvent(widget.eventID);
      if (response.statusCode == 200) {
        setState(() {
          _attendances = (response.data['attendances'] as List)
              .map((e) => Attendance.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load attendance');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int attendanceID, String status) async {
    try {
      final response = await _apiService.updateAttendanceStatus(attendanceID, status);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Status updated successfully');
        _loadAttendance();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'Event Attendance'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _attendances.isEmpty
              ? Center(child: Text('No attendance records found', style: AppTheme.bodyLarge))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMD),
                      child: Text('Total: ${_attendances.length}', style: AppTheme.heading4),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _attendances.length,
                        itemBuilder: (context, index) {
                          final attendance = _attendances[index];
                          return ModernCard(
                            child: ListTile(
                              title: Text('${attendance.student?.firstName ?? ''} ${attendance.student?.lastName ?? ''}', style: AppTheme.heading5),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Student ID: ${attendance.studentID}', style: AppTheme.bodySmall),
                                  Text('Status: ${attendance.status}', style: AppTheme.bodySmall),
                                  Text('Marked at: ${formatDateTime(attendance.markedAt)}', style: AppTheme.bodySmall),
                                  if (attendance.checkInTime != null) Text('Check-in: ${formatDateTime(attendance.checkInTime)}', style: AppTheme.bodySmall),
                                  if (attendance.checkOutTime != null) Text('Check-out: ${formatDateTime(attendance.checkOutTime)}', style: AppTheme.bodySmall),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                onSelected: (value) => _updateStatus(attendance.id, value as String),
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'present', child: Text('Present')),
                                  PopupMenuItem(value: 'absent', child: Text('Absent')),
                                  PopupMenuItem(value: 'late', child: Text('Late')),
                                  PopupMenuItem(value: 'excused', child: Text('Excused')),
                                ],
                                child: _getStatusIcon(attendance.status),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'late':
        return Icon(Icons.schedule, color: Colors.orange);
      case 'absent':
        return Icon(Icons.cancel, color: Colors.red);
      case 'excused':
        return Icon(Icons.info, color: Colors.blue);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }
}

