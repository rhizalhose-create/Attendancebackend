# 🚀 Localhost Setup Guide - Attendance System

## Quick Start (5 Minutes)

### 1. Prerequisites
```bash
# Install PostgreSQL (local or use Docker)
# Install Go 1.19+
# Clone the project
```

### 2. Local Database Setup

#### Option A: PostgreSQL on Windows (Recommended)
```bash
# Install PostgreSQL from: https://www.postgresql.org/download/windows/
# During installation:
# - Username: postgres
# - Password: postgres (or your choice)
# - Port: 5432

# Open PowerShell as Admin
psql -U postgres

# In psql:
CREATE DATABASE attendance_local;
CREATE USER attendance_user WITH PASSWORD 'attendance_password';
ALTER ROLE attendance_user WITH CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE attendance_local TO attendance_user;
\q
```

#### Option B: PostgreSQL with Docker
```bash
docker run --name postgres-attendance -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=attendance_local -p 5432:5432 -d postgres:15

# Verify:
docker ps
```

### 3. Create .env.local File

Create `c:\Users\ASUS\Attendancebackend\.env.local`:

```dotenv
# ===== LOCAL DEVELOPMENT =====
# Database (Local PostgreSQL)
DB_HOST=localhost
DB_PORT=5432
DB_USER=attendance_user
DB_PASSWORD=attendance_password
DB_NAME=attendance_local

# Server Config
APP_PORT=3000

# SMTP Config (Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# JWT Secret
JWT_SECRET=your-secret-key-min-32-chars-long-12345

# Environment
ENVIRONMENT=development
```

**⚠️ Important**: Get Gmail App Password:
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer"
3. Copy the generated 16-character password
4. Set `SMTP_PASS=` to this value

### 4. Update Database Connection

Edit `connection/db.go` to support local environment:

```go
func Connect() {
	godotenv.Load(".env.local")      // Load local env first
	godotenv.Load()                  // Then load .env for fallback

	// Try local config first
	dsn := ""
	
	// Check for local database config
	localHost := os.Getenv("DB_HOST")
	if localHost != "" {
		dsn = "host=" + localHost +
			" user=" + os.Getenv("DB_USER") +
			" password=" + os.Getenv("DB_PASSWORD") +
			" dbname=" + os.Getenv("DB_NAME") +
			" port=" + os.Getenv("DB_PORT") +
			" sslmode=disable"
		log.Println("✅ Using local database")
	} else {
		// Fall back to cloud database
		dsn = os.Getenv("DATABASE_URL")
		if dsn != "" {
			log.Println("✅ Using cloud database (Neon)")
		}
	}

	if dsn == "" {
		log.Fatal("❌ No database configuration found!")
	}

	// Connect to PostgreSQL
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		DisableForeignKeyConstraintWhenMigrating: true,
	})
	if err != nil {
		log.Fatal("❌ Failed to connect to DB:", err)
	}

	// ... rest of code
}
```

### 5. Run the Server

```bash
cd c:\Users\ASUS\Attendancebackend

# Load dependencies
go mod tidy

# Run server
go run main.go

# Should output:
# 🚀 Server running on port 3000
# 🌍 Health: http://localhost:3000/health
# 📡 Ping: http://localhost:3000/ping
```

### 6. Test Endpoints

```bash
# Health Check
curl http://localhost:3000/health

# Should return:
# {
#   "status": "ok",
#   "service": "attendance-backend",
#   "time": "2026-01-14T..."
# }
```

---

## Testing Verification Code Resend on Localhost

### Create Test User

```bash
# 1. Register a user
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@localhost.local",
    "password": "SecurePass123!",
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User",
    "course": "BSCS",
    "year_level": "1st Year",
    "student_id": "2024-0001"
  }'

# Response should include a token
```

### Test Resend Verification

```bash
# 2. Resend verification code (user still pending)
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "test@localhost.local"}'

# Expected: 200 OK
# Response:
# {
#   "message": "Verification code resent successfully. Please check your email.",
#   "student_id": "2024-0001",
#   "token": "eyJ...",
#   "status": "success"
# }
```

### Test Already Verified User

```bash
# 3. Verify the email first
curl -X POST http://localhost:3000/verify \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@localhost.local",
    "code": "123456"  # from email
  }'

# 4. Now try to resend (should fail with 409)
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "test@localhost.local"}'

# Expected: 409 Conflict
# {
#   "error": "user is already verified. Please login to your account",
#   "status": "already_verified"
# }
```

### Test Non-Existent Email

```bash
# 5. Resend for non-existent email
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "nonexistent@localhost.local"}'

# Expected: 404 Not Found
# {
#   "error": "email not found. Please check if you registered with this email",
#   "status": "not_found"
# }
```

---

## Postman Collection for Localhost

### Set up Postman Variables

1. Create new Collection: `Attendance Localhost`
2. Add these variables:
   - `base_url`: `http://localhost:3000`
   - `email`: `test@localhost.local`
   - `password`: `SecurePass123!`
   - `token`: `` (auto-filled after login)

### Test Requests

```
1. POST {{base_url}}/register
   Body: { email, password, username, first_name, last_name, course, year_level }

2. POST {{base_url}}/resend-verification
   Body: { "email": "{{email}}" }
   Expected: 200 OK

3. POST {{base_url}}/verify
   Body: { email, code, token }
   Expected: 200 OK

4. POST {{base_url}}/resend-verification
   Body: { "email": "{{email}}" }
   Expected: 409 Conflict (already verified)
```

---

## Troubleshooting

### Issue: "Failed to connect to database"
**Solution**: 
```bash
# Check PostgreSQL is running:
psql -U postgres -c "SELECT version();"

# Or restart Docker container:
docker start postgres-attendance
```

### Issue: "SMTP_USER is not set"
**Solution**: 
```bash
# Make sure .env.local exists and has SMTP settings
cat .env.local | grep SMTP

# Or manually set in PowerShell:
$env:SMTP_HOST = "smtp.gmail.com"
$env:SMTP_PORT = "587"
$env:SMTP_USER = "your-email@gmail.com"
$env:SMTP_PASS = "your-app-password"
```

### Issue: "Email failed to send"
**Solution**:
```bash
# Check Gmail App Password (not regular password)
# Go to: https://myaccount.google.com/apppasswords

# Or use a test SMTP service:
# https://mailtrap.io/ (free plan)
# https://ethereal.email/ (free)

SMTP_HOST=smtp.mailtrap.io
SMTP_PORT=2525
SMTP_USER=your-mailtrap-user
SMTP_PASS=your-mailtrap-pass
```

### Issue: "Port 3000 already in use"
**Solution**:
```bash
# Change port in .env.local:
APP_PORT=3001

# Or kill process using port 3000:
# In PowerShell (as Admin):
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

---

## Database Schema Check

```bash
# Connect to local database:
psql -U attendance_user -d attendance_local

# List tables:
\dt

# Check pending_users table:
SELECT * FROM pending_users;

# Check users table:
SELECT * FROM users;

# Exit:
\q
```

---

## Development Workflow

### 1. Start PostgreSQL
```bash
# If using local PostgreSQL:
# (Usually starts automatically on Windows)

# If using Docker:
docker start postgres-attendance
```

### 2. Start Backend Server
```bash
cd c:\Users\ASUS\Attendancebackend
go run main.go
```

### 3. Test with Postman/cURL
```bash
# Use localhost:3000 endpoints
# See examples above
```

### 4. Check Logs
```bash
# Server logs show in terminal
# Database logs in PostgreSQL

# Watch file changes (optional):
# Install air: go install github.com/cosmtrek/air@latest
# Run: air
```

---

## Production vs Localhost

| Setting | Localhost | Production |
|---------|-----------|-----------|
| Database | Local PostgreSQL | Neon Cloud |
| SMTP | Gmail/Mailtrap | Gmail/SendGrid |
| Port | 3000 (local) | 443 (HTTPS) |
| CORS | * (all origins) | Specific domains |
| SSL | Disabled | Required |
| Env File | .env.local | .env |

---

## Complete Setup Script

Save as `setup-localhost.ps1`:

```powershell
# Setup Attendance Backend for Localhost

Write-Host "🚀 Setting up Attendance Backend..." -ForegroundColor Green

# 1. Check Go installation
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Go is not installed. Please install Go 1.19+" -ForegroundColor Red
    exit 1
}

# 2. Check PostgreSQL
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  PostgreSQL not found in PATH. Make sure it's installed." -ForegroundColor Yellow
}

# 3. Get database details
$dbHost = Read-Host "Enter DB Host (default: localhost)"
$dbPort = Read-Host "Enter DB Port (default: 5432)"
$dbUser = Read-Host "Enter DB User (default: attendance_user)"
$dbPass = Read-Host "Enter DB Password (default: attendance_password)" -AsSecureString
$smtpUser = Read-Host "Enter SMTP User (Gmail account)"
$smtpPass = Read-Host "Enter SMTP Password (App password)" -AsSecureString

$dbHost = if ($dbHost -eq "") { "localhost" } else { $dbHost }
$dbPort = if ($dbPort -eq "") { "5432" } else { $dbPort }
$dbUser = if ($dbUser -eq "") { "attendance_user" } else { $dbUser }
$dbName = "attendance_local"
$appPort = "3000"

# 4. Create .env.local
$envContent = @"
# Database Config (Local)
DB_HOST=$dbHost
DB_PORT=$dbPort
DB_USER=$dbUser
DB_PASSWORD=$(ConvertFrom-SecureString -AsPlainText $dbPass)
DB_NAME=$dbName

# Server Config
APP_PORT=$appPort

# SMTP Config
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=$smtpUser
SMTP_PASS=$(ConvertFrom-SecureString -AsPlainText $smtpPass)

# JWT Secret
JWT_SECRET=your-secret-key-min-32-chars-long-12345

# Environment
ENVIRONMENT=development
"@

Set-Content -Path ".env.local" -Value $envContent
Write-Host "✅ Created .env.local" -ForegroundColor Green

# 5. Install dependencies
Write-Host "📦 Installing Go dependencies..." -ForegroundColor Green
go mod tidy

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "🚀 Start server with: go run main.go" -ForegroundColor Green
```

Run with:
```bash
powershell -ExecutionPolicy Bypass -File setup-localhost.ps1
```

---

## Next Steps

1. ✅ Set up local PostgreSQL
2. ✅ Create .env.local file
3. ✅ Update connection/db.go to load .env.local
4. ✅ Run `go run main.go`
5. ✅ Test endpoints with Postman
6. ✅ Test verification resend flow

**Everything works on localhost! 🎉**
