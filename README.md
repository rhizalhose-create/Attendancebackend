# Attendance System Backend

A comprehensive school attendance management system built with Go (Fiber framework) and PostgreSQL.

## Features

### ✅ Security Improvements
- **CORS Configuration**: Configurable allowed origins (set via `ALLOWED_ORIGINS` env variable)
- **Rate Limiting**: 100 requests per minute per IP address
- **Input Validation**: Email, password strength, student ID, and image validation
- **Password Security**: Bcrypt hashing with cost factor 12
- **Account Verification**: Email-based verification system

### ✅ User Management
- **Registration**: With profile picture upload (base64 encoded)
- **Email Verification**: 6-digit code sent via email
- **Login**: By Student ID or Email
- **Password Reset**: Secure code-based reset system
- **Role Management**: Student, Faculty, Admin, SuperAdmin roles

### ✅ Attendance System
- **Event Management**: Create, update, delete events (classes/meetings)
- **Multiple Events**: Support for unlimited events
- **QR Code Attendance**: Automatic QR code generation for events
- **Attendance Marking**: 
  - QR scan method
  - Manual entry (for admin/faculty)
  - Automatic late detection (15 minutes after start time)
- **Attendance Status**: Present, Absent, Late, Excused
- **Location Tracking**: Optional GPS coordinates
- **Statistics**: Attendance rates and reports

### ✅ Profile Pictures
- Base64 encoded image upload during registration
- Supports JPEG, PNG, GIF, WebP formats
- Maximum size: 2MB
- Stored in database (consider cloud storage for production)

## API Endpoints

### Authentication
- `POST /register` - Register new user (with profile picture)
- `POST /login` - Login with Student ID
- `POST /login/email` - Login with Email
- `POST /verify` - Verify email with code
- `POST /forgot-password` - Request password reset code
- `POST /reset-password` - Reset password with code
- `POST /resend-reset-code` - Resend reset code

### Events
- `GET /events` - Get all events (with filters: course, section, year_level, status, is_active)
- `GET /events/my-events` - Get events for current student
- `GET /events/:id` - Get single event
- `POST /events` - Create event (Faculty/Admin only)
- `PUT /events/:id` - Update event (Faculty/Admin only)
- `DELETE /events/:id` - Delete event (Faculty/Admin only)

### Attendance
- `POST /attendance/mark` - Mark attendance
- `GET /attendance/my-attendance` - Get own attendance records
- `GET /attendance/stats` - Get attendance statistics
- `GET /events/:event_id/attendance` - Get attendance for specific event
- `PUT /attendance/:id/status` - Update attendance status (Admin/Faculty only)

### Admin
- `GET /admin/users` - Get all users (SuperAdmin only)
- `POST /admin/promote` - Promote user to different role (SuperAdmin only)

## Request Examples

### Register with Profile Picture
```json
POST /register
{
  "email": "student@school.edu",
  "password": "SecurePass123",
  "username": "johndoe",
  "first_name": "John",
  "last_name": "Doe",
  "middle_name": "M",
  "course": "Computer Science",
  "year_level": "3rd Year",
  "section": "A",
  "department": "IT",
  "college": "Engineering",
  "contact_number": "+1234567890",
  "address": "123 Main St",
  "profile_picture": "data:image/png;base64,iVBORw0KGgoAAAANS..."
}
```

### Create Event
```json
POST /events
Authorization: Bearer {student_id}
{
  "title": "Mathematics 101 - Lecture",
  "description": "Introduction to Calculus",
  "event_date": "2024-01-15",
  "start_time": "09:00",
  "end_time": "10:30",
  "location": "Room 101",
  "course": "Mathematics 101",
  "section": "A",
  "year_level": "1st Year",
  "department": "Mathematics",
  "college": "Science"
}
```

### Mark Attendance
```json
POST /attendance/mark
Authorization: Bearer {student_id}
{
  "event_id": 1,
  "status": "present",
  "method": "qr_scan",
  "latitude": 14.5995,
  "longitude": 120.9842,
  "notes": "On time"
}
```

## Environment Variables

Create a `.env` file:

```env
# Database
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=attendance_db
DB_PORT=5432

# Server
APP_PORT=3000

# CORS (comma-separated for multiple origins)
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# SMTP (for email)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

## Database Setup

Run the SQL file to create tables:
```bash
psql -U postgres -d attendance_db -f attendance.sql
```

Or let GORM auto-migrate (tables will be created automatically on first run).

## Installation

```bash
# Install dependencies
go mod download

# Run the server
go run main.go
```

## Security Notes

1. **CORS**: Change `ALLOWED_ORIGINS` in production to specific domains
2. **Profile Pictures**: Consider using cloud storage (S3, Cloudinary) instead of database
3. **Rate Limiting**: Adjust limits in `middleware/rate_limit.go` based on needs
4. **Password Policy**: Currently requires 8+ chars, uppercase, lowercase, number
5. **JWT Tokens**: Consider implementing JWT tokens instead of Student ID in Bearer token

## Improvements Made

1. ✅ Fixed CORS security vulnerability (configurable origins)
2. ✅ Added rate limiting (100 req/min per IP)
3. ✅ Added input validation (email, password, student ID, images)
4. ✅ Added profile picture upload to registration
5. ✅ Created complete attendance tracking system
6. ✅ Added event management (create, update, delete)
7. ✅ Added attendance statistics and reporting
8. ✅ Improved error handling
9. ✅ Added proper middleware for authentication
10. ✅ Support for multiple events and attendance records

## Default SuperAdmin

- StudentID: `SUPERADMIN`
- Password: `superadmin123`

**⚠️ Change this immediately in production!**

## License

MIT

