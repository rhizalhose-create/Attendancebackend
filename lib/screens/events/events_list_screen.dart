import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'event_details_screen.dart';

class EventsListScreen extends StatefulWidget {
  @override
  _EventsListScreenState createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final ApiService _apiService = ApiService();
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllEvents();
      if (response.statusCode == 200) {
        setState(() {
          _events = (response.data['events'] as List)
              .map((e) => Event.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load events');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppTheme.primaryColor;
      case 'ongoing':
        return AppTheme.successColor;
      case 'completed':
        return AppTheme.textSecondary;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
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
                      'Events',
                      style: AppTheme.heading3.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadEvents,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : _events.isEmpty
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.all(AppTheme.spacingXL),
                            margin: EdgeInsets.all(AppTheme.spacingMD),
                            decoration: AppTheme.cardDecoration,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: AppTheme.textSecondary),
                                SizedBox(height: AppTheme.spacingMD),
                                Text(
                                  'No events found',
                                  style: AppTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEvents,
                          color: AppTheme.primaryColor,
                          child: ListView.builder(
                            padding: EdgeInsets.all(AppTheme.spacingMD),
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: AppTheme.spacingMD),
                                decoration: AppTheme.cardDecoration,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventDetailsScreen(event: event),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                    child: Padding(
                                      padding: EdgeInsets.all(AppTheme.spacingMD),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  event.title,
                                                  style: AppTheme.heading3,
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: AppTheme.spacingSM,
                                                  vertical: AppTheme.spacingXS,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(event.status).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                                ),
                                                child: Text(
                                                  event.status.toUpperCase(),
                                                  style: AppTheme.bodySmall.copyWith(
                                                    color: _getStatusColor(event.status),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: AppTheme.spacingMD),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                                              SizedBox(width: AppTheme.spacingXS),
                                              Text(
                                                DateFormat('MMM dd, yyyy').format(event.eventDate),
                                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: AppTheme.spacingXS),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                                              SizedBox(width: AppTheme.spacingXS),
                                              Text(
                                                '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                          if (event.location != null) ...[
                                            SizedBox(height: AppTheme.spacingXS),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                                                SizedBox(width: AppTheme.spacingXS),
                                                Expanded(
                                                  child: Text(
                                                    event.location!,
                                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          SizedBox(height: AppTheme.spacingSM),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'View Details',
                                                style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                                              ),
                                              SizedBox(width: AppTheme.spacingXS),
                                              Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryColor),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
