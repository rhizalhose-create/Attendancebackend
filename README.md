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

## reCAPTCHA Integration

This project supports **reCAPTCHA v2 (Checkbox)** and v3 (Invisible). Use v2 for a user-friendly checkbox or v3 for invisible verification.

### Frontend — reCAPTCHA v2 (Checkbox - Recommended for Android/Mobile)

1. Add the script to your HTML:

```html
<script src="https://www.google.com/recaptcha/api.js"></script>
```

2. Add the checkbox widget and login form:

```html
<form id="loginForm">
  <input type="text" id="studentId" placeholder="Student ID or Email" required>
  <input type="password" id="password" placeholder="Password" required>
  
  <!-- reCAPTCHA v2 Checkbox -->
  <div class="g-recaptcha" data-sitekey="YOUR_SITE_KEY"></div>
  
  <button type="submit">Login</button>
</form>
```

3. On form submit, get the token and send it to the backend:

```javascript
document.getElementById('loginForm').addEventListener('submit', (e) => {
  e.preventDefault();
  const token = grecaptcha.getResponse();
  
  if (!token) {
    alert('Please complete the reCAPTCHA');
    return;
  }
  
  fetch('/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      student_id: document.getElementById('studentId').value,
      password: document.getElementById('password').value,
      recaptcha_token: token
    })
  })
  .then(r => r.json())
  .then(data => {
    if (data.error) {
      alert('Login failed: ' + data.error);
      grecaptcha.reset(); // Reset on error
    } else {
      alert('Login successful!');
      // Store token, redirect to dashboard, etc.
    }
  });
});
```

### Frontend — reCAPTCHA v3 (Invisible - Automatic)

1. Add the script (replace `YOUR_SITE_KEY`):

```html
<script src="https://www.google.com/recaptcha/api.js?render=YOUR_SITE_KEY"></script>
```

2. On login button click:

```javascript
const SITE_KEY = "YOUR_SITE_KEY";
document.getElementById('loginBtn').addEventListener('click', () => {
  grecaptcha.ready(() => {
    grecaptcha.execute(SITE_KEY, { action: 'login' }).then(token => {
      fetch('/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          student_id: studentIdValue,
          password: passwordValue,
          recaptcha_token: token
        })
      }).then(r => r.json()).then(console.log);
    });
  });
});
```

### Backend Configuration

- **Site key**: Register at [Google reCAPTCHA Admin](https://www.google.com/recaptcha/admin) and copy the **Site Key**.
- **Secret key**: Copy the **Secret Key** and add it to your `.env`:

```env
RECAPTCHA_SITE_KEY=YOUR_SITE_KEY
RECAPTCHA_SECRET_KEY=YOUR_SECRET_KEY
```

Or use the alternate variable name:

```env
RECAPTCHA_SITE_KEY=YOUR_SITE_KEY
RECAPTCHA_SECRET=YOUR_SECRET_KEY
```

### Endpoints Requiring reCAPTCHA

reCAPTCHA verification is required for the following endpoints to prevent abuse:

- `POST /register` — User registration
- `POST /login` — Login by Student ID
- `POST /login/email` — Login by Email
- `POST /forgot-password` — Password reset request
- `POST /events` — Create new event (faculty/admin only)
- `POST /attendance` — Mark attendance

Include `recaptcha_token` in the JSON payload for these requests.

### Token Expiration

reCAPTCHA tokens expire after ~2 minutes. If you get `timeout-or-duplicate` errors, get a fresh token from the frontend using `grecaptcha.reset()` and `grecaptcha.execute()` again.

### API Response Codes

- `200 OK` — Request successful (reCAPTCHA passed).
- `400 Bad Request` — Missing, invalid, or expired `recaptcha_token`.
- `401 Unauthorized` — Invalid credentials or unauthorized.
- `403 Forbidden` — Action mismatch or insufficient permissions.
- `500 Internal Server Error` — reCAPTCHA verification or server error.

### Development / Local Testing

If `RECAPTCHA_SECRET_KEY` is not set in `.env`, the backend will **skip reCAPTCHA verification** automatically (useful for local development without keys).

Log message on startup:
```
RECAPTCHA secret loaded
```

Or if missing:
```
RECAPTCHA secret not set — verification will be skipped
```

### Debugging

Server logs reCAPTCHA verification results. Check the backend console for:

```
recaptcha siteverify: success=true errors=[]
recaptcha verification failed: errors=[invalid-input-response]
```

If you see network errors, check:
1. Firewall allows outbound HTTPS to `www.google.com:443`
2. Proxy settings (if behind corporate proxy)
3. DNS resolution for `www.google.com`

### Testing Endpoint (Debug)

Test reCAPTCHA verification directly:

```bash
curl -X POST http://localhost:3000/debug/recaptcha \
  -H "Content-Type: application/json" \
  -d '{"token": "YOUR_TOKEN", "action": "login"}'
```

Response (success):
```json
{"ok": true, "message": "verification passed"}
```

Response (failure):
```json
{"ok": false, "message": "verification failed"}
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

