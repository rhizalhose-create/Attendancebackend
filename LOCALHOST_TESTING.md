# Localhost Testing Guide

## Quick Test Commands

### 1. Health Check
```bash
# Check if server is running
curl http://localhost:3000/health

# Expected Response (200 OK):
{
  "status": "ok",
  "service": "attendance-backend",
  "time": "2026-01-14T10:30:45.123456Z"
}
```

### 2. Test Registration
```bash
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@localhost.local",
    "password": "SecurePass123!",
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User",
    "course": "BSCS",
    "year_level": "1st Year"
  }'

# Save the response token for next tests
```

### 3. Test Resend Verification (Pending User)
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "testuser@localhost.local"}'

# Expected Response (200 OK):
{
  "message": "Verification code resent successfully. Please check your email.",
  "student_id": "260114-XXXX",
  "token": "eyJhbGc...",
  "status": "success"
}
```

### 4. Test Resend Verification (Non-Existent Email)
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "unknown@localhost.local"}'

# Expected Response (404 Not Found):
{
  "error": "email not found. Please check if you registered with this email",
  "status": "not_found"
}
```

### 5. Test Verify Email
```bash
# Get the code from the email (or check database)
# SELECT verification_code FROM pending_users WHERE email = 'testuser@localhost.local';

curl -X POST http://localhost:3000/verify \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@localhost.local",
    "code": "123456"
  }'

# Expected Response (200 OK):
{
  "message": "Email verification successful",
  "status": "success"
}
```

### 6. Test Resend Verification (Already Verified User)
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "testuser@localhost.local"}'

# Expected Response (409 Conflict):
{
  "error": "user is already verified. Please login to your account",
  "status": "already_verified"
}
```

---

## Database Query Testing

```bash
# Connect to local database
psql -U attendance_user -d attendance_local

# Check pending users
SELECT id, email, student_id, verification_code, expires_at FROM pending_users;

# Check verified users
SELECT id, email, student_id, is_verified, verified_at FROM users;

# Check password resets
SELECT id, email, reset_code, expires_at FROM password_resets;

# Delete test data
DELETE FROM pending_users WHERE email LIKE '%localhost.local%';
DELETE FROM users WHERE email LIKE '%localhost.local%';

# Exit
\q
```

---

## PowerShell Test Script

Save as `test-localhost.ps1`:

```powershell
# Attendance Backend - Localhost Testing

$baseUrl = "http://localhost:3000"
$testEmail = "test-$(Get-Date -Format 'HHmmss')@localhost.local"
$testPassword = "SecurePass123!"

Write-Host "🧪 Testing Attendance Backend on Localhost" -ForegroundColor Cyan
Write-Host ""

# 1. Health Check
Write-Host "1️⃣  Testing Health Check..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✅ Health: $($response.status)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Health check failed!" -ForegroundColor Red
    Write-Host "Make sure server is running on $baseUrl" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 2. Register User
Write-Host "2️⃣  Testing Registration..." -ForegroundColor Green
$registerBody = @{
    email = $testEmail
    password = $testPassword
    username = "testuser"
    first_name = "Test"
    last_name = "User"
    course = "BSCS"
    year_level = "1st Year"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "✅ Registration: $($response.status)" -ForegroundColor Green
    $verificationToken = $response.token
    $studentId = $response.student_id
    Write-Host "   Student ID: $studentId" -ForegroundColor Gray
    Write-Host "   Token: $($verificationToken.Substring(0, 20))..." -ForegroundColor Gray
}
catch {
    Write-Host "❌ Registration failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""

# 3. Resend Verification (Pending)
Write-Host "3️⃣  Testing Resend Verification (Pending)..." -ForegroundColor Green
$resendBody = @{ email = $testEmail } | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/resend-verification" -Method Post -Body $resendBody -ContentType "application/json"
    Write-Host "✅ Resend: $($response.status)" -ForegroundColor Green
    Write-Host "   Message: $($response.message)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Resend failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""

# 4. Test Non-Existent Email
Write-Host "4️⃣  Testing Resend with Non-Existent Email..." -ForegroundColor Green
$unknownBody = @{ email = "unknown-$(Get-Date -Format 'HHmmss')@localhost.local" } | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/resend-verification" -Method Post -Body $unknownBody -ContentType "application/json"
}
catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✅ Expected 404 for non-existent email" -ForegroundColor Green
        $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   Status: $($errorResponse.status)" -ForegroundColor Gray
        Write-Host "   Error: $($errorResponse.error)" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ Unexpected error!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ All tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Check database: psql -U attendance_user -d attendance_local" -ForegroundColor Gray
Write-Host "2. Verify email: SELECT * FROM pending_users WHERE email = '$testEmail';" -ForegroundColor Gray
Write-Host "3. Test email verification with the code from the database" -ForegroundColor Gray
```

Run with:
```powershell
powershell -ExecutionPolicy Bypass -File test-localhost.ps1
```

---

## Common Issues & Solutions

### Issue: "Connection refused on port 3000"
```
Server isn't running!

Solution:
1. Run: go run main.go
2. Check for error messages
3. Make sure PORT 3000 is not in use:
   netstat -ano | findstr :3000
```

### Issue: "Database connection failed"
```
Database isn't running or credentials are wrong

Solution:
1. Check PostgreSQL is running
2. Verify .env.local has correct DB credentials
3. Test connection:
   psql -h localhost -U attendance_user -d attendance_local
```

### Issue: "SMTP_USER not set"
```
Email configuration is missing

Solution:
1. Check .env.local has SMTP settings
2. For Gmail: Get app password from:
   https://myaccount.google.com/apppasswords
3. Don't use your regular Gmail password
```

### Issue: "Port 3000 already in use"
```
Another process is using the port

Solution:
Option 1 - Kill the process:
  netstat -ano | findstr :3000
  taskkill /PID <PID> /F

Option 2 - Use different port:
  Change APP_PORT in .env.local
  go run main.go
```

### Issue: "Go modules not found"
```
Dependencies not installed

Solution:
go mod tidy
go mod download
```

---

## Postman Collection

Create a new Postman collection with these requests:

### Variables
```
base_url = http://localhost:3000
test_email = test-{{$timestamp}}@localhost.local
test_password = SecurePass123!
verification_token = (auto-filled from register)
```

### Requests

**1. Health Check**
```
GET {{base_url}}/health
```

**2. Register User**
```
POST {{base_url}}/register
Body (JSON):
{
  "email": "{{test_email}}",
  "password": "{{test_password}}",
  "username": "testuser",
  "first_name": "Test",
  "last_name": "User",
  "course": "BSCS",
  "year_level": "1st Year"
}

Test (Post-request script):
var jsonData = pm.response.json();
pm.environment.set("verification_token", jsonData.token);
pm.environment.set("student_id", jsonData.student_id);
```

**3. Resend Verification**
```
POST {{base_url}}/resend-verification
Body (JSON):
{
  "email": "{{test_email}}"
}
```

**4. Get Verification Code (from DB)**
```
Run this SQL in psql:
SELECT verification_code FROM pending_users WHERE email = 'your-test-email@localhost.local';
```

**5. Verify Email**
```
POST {{base_url}}/verify
Body (JSON):
{
  "email": "{{test_email}}",
  "code": "your-code-from-db",
  "token": "{{verification_token}}"
}
```

**6. Resend After Verification (Should fail with 409)**
```
POST {{base_url}}/resend-verification
Body (JSON):
{
  "email": "{{test_email}}"
}

Expected: 409 Conflict
```

---

## Monitoring

### Watch Server Logs
```bash
# Start server with logging
go run main.go

# Look for:
# ✅ Database connected successfully!
# 📧 AuthService.resendVerificationCode called for ...
# ✅ Verification email resent successfully to ...
```

### Check Database Activity
```bash
# Watch for inserts
SELECT * FROM pending_users ORDER BY created_at DESC LIMIT 5;

# Watch for verifications
SELECT * FROM users WHERE is_verified = true ORDER BY verified_at DESC LIMIT 5;
```

---

## Success Criteria

✅ All tests pass:
- [x] Health check returns 200
- [x] Register creates pending user
- [x] Resend to pending user returns 200
- [x] Resend to non-existent returns 404
- [x] Resend to verified user returns 409
- [x] Email sending works (or gracefully fails)

🎉 **System is working on localhost!**
