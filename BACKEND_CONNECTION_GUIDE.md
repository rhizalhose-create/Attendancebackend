# 📱 Backend Connection Guide - Flutter to Go Server

## ✅ What Was Fixed

The backend server has been configured to listen on **`0.0.0.0:3000`** instead of `localhost:3000`, allowing connections from other devices on your network.

---

## 🔧 Configuration

### Backend (.env file)
```env
# Server Config
APP_PORT=3000
ENV=development

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-min-32-chars-long-please-change-this

# CORS Configuration - Allow mobile/external connections
ALLOWED_ORIGINS=http://192.168.1.*:*,http://localhost:3000,http://localhost:3001,http://0.0.0.0:3000

# Database
DB_HOST=192.168.1.13
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=123456
DB_NAME=Attended
```

### Backend Listen Address (main.go)
```go
app.Listen("0.0.0.0:" + port)  // Listens on ALL network interfaces
```

**Result:**
```
Fiber v2.52.10
http://127.0.0.1:3000
(bound on host 0.0.0.0 and port 3000)  ✅
```

---

## 📍 Finding Your Backend IP Address

Run this command on your computer:

### Windows (PowerShell)
```powershell
ipconfig

# Look for "IPv4 Address" under your Wi-Fi adapter
# Example: 192.168.1.13
```

### Mac/Linux
```bash
ifconfig

# Look for "inet" address (typically starts with 192.168.x.x)
```

**Your IP:** `192.168.1.13` (from your .env file)

---

## 📱 Flutter App Configuration

Update `api_service.dart`:

```dart
class ApiService {
  // ❌ OLD (doesn't work on other devices)
  // static const String baseUrl = 'http://localhost:3000';

  // ✅ NEW (works on other devices)
  static const String baseUrl = 'http://192.168.1.13:3000';
  
  // Or use your computer's actual IP from ipconfig
  // static const String baseUrl = 'http://<YOUR_COMPUTER_IP>:3000';
}
```

---

## ✅ Pre-Connection Checklist

### 1️⃣ Backend Server Running
```bash
# Terminal on your computer
cd C:\Users\myzce\Downloads\Attendancebackend-dev1
go run main.go

# Expected output:
# ┌─────────────────────────────────────┐
# │ Fiber v2.52.10                      │
# │ http://127.0.0.1:3000               │
# │ (bound on host 0.0.0.0 and port 3000) │  ✅ THIS CONFIRMS IT
# └─────────────────────────────────────┘
```

### 2️⃣ Same Wi-Fi Network
- [ ] Computer connected to Wi-Fi: `YourWiFiName`
- [ ] Phone connected to same Wi-Fi: `YourWiFiName`

### 3️⃣ Firewall Allows Port 3000
```powershell
# Windows Firewall - Allow port 3000
# Settings > Privacy & Security > Windows Defender Firewall > Allow an app
# Add port 3000 for Go
```

### 4️⃣ Test Connectivity

**On your phone (mobile hotspot or browser):**
```
http://192.168.1.13:3000/test
```

**Expected response:**
```json
{
  "status": "ok",
  "message": "Go backend is working!"
}
```

**Health check:**
```
http://192.168.1.13:3000/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "service": "attendance-system"
}
```

---

## 🔌 Flutter API Endpoints

### Login
```dart
POST http://192.168.1.13:3000/login
Content-Type: application/json

{
  "student_id": "251213-6219",
  "password": "MyPassword123!"
}

// Response
{
  "message": "Login successful",
  "student_id": "251213-6219",
  "role": "faculty",
  "first_name": "John",
  "last_name": "Doe",
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Get Profile
```dart
GET http://192.168.1.13:3000/profile
Authorization: Bearer <access_token>

// Response
{
  "message": "Profile retrieved successfully",
  "student_id": "251213-6219",
  "email": "user@email.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "faculty",
  "course": "CS",
  "year_level": "3",
  ...
}
```

### Get Events
```dart
GET http://192.168.1.13:3000/events
Authorization: Bearer <access_token>

// Response
{
  "events": [
    {
      "id": 1,
      "title": "CS Lecture",
      "description": "...",
      "event_date": "2025-12-14T10:00:00Z",
      "start_time": "2025-12-14T10:00:00Z",
      "end_time": "2025-12-14T11:30:00Z",
      "location": "Room 101",
      "qr_code_data": "data:image/png;base64,..."
    }
  ]
}
```

---

## 🧪 Testing with curl

### From your computer (localhost)
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"student_id":"251213-6219","password":"MyPassword123!"}'
```

### From another device (network IP)
```bash
curl -X POST http://192.168.1.13:3000/login \
  -H "Content-Type: application/json" \
  -d '{"student_id":"251213-6219","password":"MyPassword123!"}'
```

### Test health check
```bash
# Local
curl http://localhost:3000/health

# Network
curl http://192.168.1.13:3000/health
```

---

## 🚨 Troubleshooting

### ❌ "Cannot connect to server"
```
Error: Failed to connect to 192.168.1.13:3000
```

**Solutions:**
1. ✅ Verify backend is running: `go run main.go`
2. ✅ Check Fiber shows `0.0.0.0` binding
3. ✅ Ping computer from phone: `ping 192.168.1.13`
4. ✅ Test with browser: `http://192.168.1.13:3000/test`

### ❌ "CORS error"
```
Access to XMLHttpRequest blocked by CORS policy
```

**Solution:** Check .env `ALLOWED_ORIGINS` includes your IP:
```env
ALLOWED_ORIGINS=http://192.168.1.*:*,http://localhost:3000
```

### ❌ "Connection timeout"
```
Timeout waiting for connection to 192.168.1.13:3000
```

**Solutions:**
1. Check firewall allows port 3000
2. Verify both devices on same Wi-Fi
3. Try disabling firewall temporarily for testing

### ❌ "Invalid token" or "401 Unauthorized"
```
{
  "error": "Invalid or expired refresh token"
}
```

**Solutions:**
1. Ensure `JWT_SECRET` is set in .env
2. Check token hasn't expired (15 min for access token)
3. Use `/refresh-token` endpoint to get new access token

---

## 📝 Dart API Service Template

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://192.168.1.13:3000';
  static String? _accessToken;
  static String? _refreshToken;

  // Login
  static Future<Map<String, dynamic>> login(String studentId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];
      return data;
    } else {
      throw Exception('Login failed');
    }
  }

  // Get Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired, refresh it
      await refreshAccessToken();
      return getProfile(); // Retry
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Refresh Token
  static Future<void> refreshAccessToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': _refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  // Get Events
  static Future<List<dynamic>> getEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['events'] ?? [];
    } else {
      throw Exception('Failed to load events');
    }
  }
}
```

---

## 🔒 Security Notes

- **JWT_SECRET**: Change to a secure random string in production
- **CORS**: Restrict ALLOWED_ORIGINS to your domain in production
- **HTTP**: Use HTTPS in production (add SSL certificate)
- **Firewall**: Only open port 3000 for trusted networks

---

## 📊 Backend Status

```
✅ Server: Running on 0.0.0.0:3000
✅ Database: Connected (PostgreSQL)
✅ JWT: Configured with secret key
✅ CORS: Configured for external connections
✅ Profile Endpoint: Available at GET /profile
✅ Health Check: Available at GET /health
✅ Test Endpoint: Available at GET /test
```

---

## 🆘 Still Having Issues?

1. **Check server logs** - Look for error messages in terminal
2. **Verify IP address** - Run `ipconfig` to confirm
3. **Test connectivity** - Use browser to access `http://192.168.1.13:3000/test`
4. **Check firewall** - Add port 3000 to Windows Firewall exceptions
5. **Restart server** - Kill previous process and restart `go run main.go`

**Common IP Addresses:**
- `127.0.0.1` - Localhost (only works on same computer)
- `192.168.1.x` - Local network (your home Wi-Fi)
- `10.0.0.x` - Corporate network
- `172.16.0.x` - Another common local range

