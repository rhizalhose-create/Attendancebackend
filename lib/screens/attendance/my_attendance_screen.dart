import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/modern_card.dart';
import '../../utils/formatters.dart';
import '../../theme/app_theme.dart';

class MyAttendanceScreen extends StatefulWidget {
  @override
  _MyAttendanceScreenState createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
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
      final response = await _apiService.getMyAttendance();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'My Attendance'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _attendances.isEmpty
              ? Center(child: Text('No attendance records found', style: AppTheme.bodyLarge))
              : RefreshIndicator(
                  onRefresh: _loadAttendance,
                  child: ListView.builder(
                    itemCount: _attendances.length,
                    itemBuilder: (context, index) {
                      final attendance = _attendances[index];
                      return ModernCard(
                        child: ListTile(
                          title: Text(attendance.event?.title ?? 'Event ${attendance.eventID}', style: AppTheme.heading4),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${attendance.status}', style: AppTheme.bodySmall),
                              Text('Date: ${formatDateTime(attendance.markedAt)}', style: AppTheme.bodySmall),
                              if (attendance.checkInTime != null) Text('Check-in: ${formatDateTime(attendance.checkInTime)}', style: AppTheme.bodySmall),
                              if (attendance.checkOutTime != null) Text('Check-out: ${formatDateTime(attendance.checkOutTime)}', style: AppTheme.bodySmall),
                            ],
                          ),
                          trailing: _getStatusIcon(attendance.status),
                        ),
                      );
                    },
                  ),
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

