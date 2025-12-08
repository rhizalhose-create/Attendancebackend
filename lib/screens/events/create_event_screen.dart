import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';
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
  List<String> _selectedCourses = [];
  List<String> get _coursesSafe => _selectedCourses;
  List<String> _selectedYearLevels = [];
  List<String> get _yearLevelsSafe => _selectedYearLevels;

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

  Future<void> _showCourseMultiSelect() async {
    // temporary set to allow cancel
    final tempSelected = List<String>.from(_coursesSafe);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Courses'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: Courses.courseList.map((course) {
                    final selected = tempSelected.contains(course);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(course),
                      onChanged: (v) {
                        setStateSB(() {
                          if (v == true) {
                            tempSelected.add(course);
                          } else {
                            tempSelected.remove(course);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedCourses = List.from(tempSelected));
                Navigator.of(context).pop();
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showYearLevelMultiSelect() async {
    final tempSelected = List<String>.from(_yearLevelsSafe);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Year Levels'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: Courses.yearLevels.map((year) {
                    final selected = tempSelected.contains(year);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(year),
                      onChanged: (v) {
                        setStateSB(() {
                          if (v == true) {
                            tempSelected.add(year);
                          } else {
                            tempSelected.remove(year);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedYearLevels = List.from(tempSelected));
                Navigator.of(context).pop();
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      if (_eventDate == null || _startTime == null || _endTime == null) {
        Fluttertoast.showToast(msg: 'Please select date and times');
        return;
      }

      if (_coursesSafe.isEmpty) {
        Fluttertoast.showToast(msg: 'Please select at least one course');
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
        // Support multiple course tags. Keep `course` and `qr_type` for backward
        // compatibility using the first selected course.
        'tagged_courses': _coursesSafe,
        if (_coursesSafe.isNotEmpty) 'course': _coursesSafe.first,
        if (_coursesSafe.isNotEmpty) 'qr_type': _coursesSafe.first,
        if (_sectionController.text.isNotEmpty) 'section': _sectionController.text.trim(),
        // Support multiple year-level tags. Keep `year_level` for backward compatibility.
        'tagged_year_levels': _yearLevelsSafe,
        if (_yearLevelsSafe.isNotEmpty) 'year_level': _yearLevelsSafe.first,
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
      } catch (e, st) {
        // Print full error and stacktrace to help debug runtime TypeErrors
        print('CreateEvent error: $e');
        print(st);
        if (e is DioError) {
          print('Response data: ${e.response?.data}');
        }
        Fluttertoast.showToast(msg: 'Failed to create event: ${e.toString()}');
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
                        // Multi-select course picker
                        InkWell(
                          onTap: _showCourseMultiSelect,
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
                                Icon(Icons.school, color: AppTheme.primaryColor),
                                SizedBox(width: AppTheme.spacingSM),
                                Expanded(
                                  child: _coursesSafe.isEmpty
                                      ? Text('Select Courses *', style: AppTheme.bodyMedium)
                                      : SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: _coursesSafe.map((c) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 6.0),
                                                child: Chip(
                                                  label: Text(c),
                                                  backgroundColor: Colors.grey[200],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _showYearLevelMultiSelect,
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
                                      Expanded(
                                        child: _yearLevelsSafe.isEmpty
                                            ? Text('Select Year Levels', style: AppTheme.bodyMedium)
                                            : SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: _yearLevelsSafe.map((y) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(right: 6.0),
                                                      child: Chip(
                                                        label: Text(y),
                                                        backgroundColor: Colors.grey[200],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                      ),
                                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                    ],
                                  ),
                                ),
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
                        // Only show create button if at least one course is selected
                        if (_selectedCourses.isNotEmpty)
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
