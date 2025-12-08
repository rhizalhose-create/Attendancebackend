# Attendance System - Flutter Frontend

Complete Flutter frontend for the Attendance System backend.

## Features

- ✅ Role-based authentication (Student, Admin, SuperAdmin)
- ✅ Automatic role-based navigation after login
- ✅ Event management (Create, View, Edit, Delete)
- ✅ Attendance tracking with QR code scanning
- ✅ Check-in/Check-out functionality
- ✅ User management (SuperAdmin only)
- ✅ Profile management with QR code display

## Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Update API URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:3000'; // Change to your backend URL
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   └── event_model.dart
├── services/                 # API services
│   └── api_service.dart
├── providers/                # State management
│   └── auth_provider.dart
└── screens/
    ├── splash_screen.dart    # Initial screen with auth check
    ├── auth/                 # Authentication screens
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── verify_email_screen.dart
    │   ├── forgot_password_screen.dart
    │   └── reset_password_screen.dart
    ├── dashboard/            # Role-based dashboards
    │   ├── student_dashboard.dart
    │   ├── admin_dashboard.dart
    │   └── superadmin_dashboard.dart
    ├── events/               # Event management
    │   ├── events_list_screen.dart
    │   ├── event_details_screen.dart
    │   └── create_event_screen.dart
    ├── attendance/           # Attendance tracking
    │   ├── mark_attendance_screen.dart
    │   ├── my_attendance_screen.dart
    │   └── event_attendance_screen.dart
    ├── admin/                # Admin functions
    │   ├── user_management_screen.dart
    │   └── promote_user_screen.dart
    └── profile/              # User profile
        └── profile_screen.dart
```

## Role-Based Navigation

After login, users are automatically redirected based on their role:

- **SuperAdmin** → SuperAdmin Dashboard
- **Admin** → Admin Dashboard  
- **Student** → Student Dashboard

## Key Features

### Authentication
- Login with Student ID or Email
- Registration with email verification
- Password reset functionality
- Role-based access control

### Events
- View all events
- Create events (Faculty/Admin/SuperAdmin)
- View event details with QR code
- Edit/Delete events (Creator/Admin only)

### Attendance
- QR code scanning for check-in/check-out
- View personal attendance records
- View event attendance (Faculty/Admin)
- Update attendance status (Faculty/Admin)

### Admin Functions (SuperAdmin)
- View all users
- Promote users to different roles
- Manage user permissions

## Dependencies

- `dio`: HTTP client
- `provider`: State management
- `shared_preferences`: Local storage
- `qr_flutter`: QR code display
- `mobile_scanner`: QR code scanning
- `fluttertoast`: Toast notifications
- `intl`: Date/time formatting

## API Integration

All API calls are handled through `ApiService` which:
- Automatically adds Authorization header with Student ID
- Handles errors and redirects on 401
- Provides methods for all backend endpoints

## Notes

- Make sure your backend is running on the configured port
- Update CORS settings in backend to allow Flutter app origin
- For production, update API URL and add proper error handling

