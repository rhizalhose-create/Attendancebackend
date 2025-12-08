import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';

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
      appBar: AppBar(
        title: Text('Event Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _attendances.isEmpty
              ? Center(child: Text('No attendance records found'))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Total: ${_attendances.length}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _attendances.length,
                        itemBuilder: (context, index) {
                          final attendance = _attendances[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                '${attendance.student?.firstName ?? ''} ${attendance.student?.lastName ?? ''}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Student ID: ${attendance.studentID}'),
                                  Text('Status: ${attendance.status}'),
                                  Text('Marked at: ${attendance.markedAt.toString().split('.')[0]}'),
                                  if (attendance.checkInTime != null)
                                    Text('Check-in: ${attendance.checkInTime!.toString().split('.')[0]}'),
                                  if (attendance.checkOutTime != null)
                                    Text('Check-out: ${attendance.checkOutTime!.toString().split('.')[0]}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                onSelected: (value) => _updateStatus(attendance.id, value),
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

