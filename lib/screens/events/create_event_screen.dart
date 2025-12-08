import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/courses.dart';
import 'events_list_screen.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _sectionController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _selectedCourse;
  String? _selectedYearLevel;

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      if (_eventDate == null || _startTime == null || _endTime == null) {
        Fluttertoast.showToast(msg: 'Please select date and times');
        return;
      }

      if (_selectedCourse == null || _selectedCourse!.isEmpty) {
        Fluttertoast.showToast(msg: 'Please select a course');
        return;
      }

      setState(() => _isLoading = true);

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_date': DateFormat('yyyy-MM-dd').format(_eventDate!),
        'start_time': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        if (_locationController.text.isNotEmpty) 'location': _locationController.text.trim(),
        'course': _selectedCourse!,
        'qr_type': _selectedCourse!, // Set qr_type to the selected course
        if (_sectionController.text.isNotEmpty) 'section': _sectionController.text.trim(),
        if (_selectedYearLevel != null && _selectedYearLevel!.isNotEmpty) 'year_level': _selectedYearLevel!,
      };

      try {
        final response = await _apiService.createEvent(data);
        if (response.statusCode == 201) {
          Fluttertoast.showToast(msg: 'Event created successfully!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EventsListScreen()),
          );
        }
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to create event');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Create Event',
                      style: AppTheme.heading3.copyWith(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingMD),
                child: Container(
                  padding: EdgeInsets.all(AppTheme.spacingLG),
                  decoration: AppTheme.cardDecoration,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Title *',
                            prefixIcon: Icons.title,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Description',
                            prefixIcon: Icons.description,
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMD,
                              vertical: AppTheme.spacingMD,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                SizedBox(width: AppTheme.spacingSM),
                                Text(
                                  _eventDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_eventDate!)
                                      : 'Select Event Date *',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectStartTime,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMD,
                                    vertical: AppTheme.spacingMD,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: AppTheme.primaryColor),
                                      SizedBox(width: AppTheme.spacingSM),
                                      Text(
                                        _startTime != null
                                            ? _startTime!.format(context)
                                            : 'Start Time *',
                                        style: AppTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: InkWell(
                                onTap: _selectEndTime,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMD,
                                    vertical: AppTheme.spacingMD,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: AppTheme.primaryColor),
                                      SizedBox(width: AppTheme.spacingSM),
                                      Text(
                                        _endTime != null
                                            ? _endTime!.format(context)
                                            : 'End Time *',
                                        style: AppTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _locationController,
                          decoration: AppTheme.inputDecoration(
                            label: 'Location',
                            prefixIcon: Icons.location_on,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        DropdownButtonFormField<String>(
                          value: _selectedCourse,
                          decoration: AppTheme.inputDecoration(
                            label: 'Course *',
                            prefixIcon: Icons.school,
                          ),
                          items: Courses.courseList.map((course) {
                            return DropdownMenuItem(
                              value: course,
                              child: Text(course, style: AppTheme.bodyMedium),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCourse = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Course is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedYearLevel,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Year Level',
                                  prefixIcon: Icons.calendar_today,
                                ),
                                items: Courses.yearLevels.map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year, style: AppTheme.bodyMedium),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedYearLevel = value);
                                },
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: TextFormField(
                                controller: _sectionController,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Section',
                                  prefixIcon: Icons.group,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingLG),
                        // Only show create button if course is selected
                        if (_selectedCourse != null && _selectedCourse!.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.buttonGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleCreate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text('Create Event', style: AppTheme.buttonText),
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingMD),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: Center(
                              child: Text(
                                'Please select a course to create event',
                                style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
