# ⚡ Localhost Quick Reference Card

## 🚀 Start Server (3 Options)

### Option 1: Click & Run (Simplest)
```bash
start-localhost.bat
```

### Option 2: PowerShell
```bash
powershell -ExecutionPolicy Bypass -File start-localhost.ps1
```

### Option 3: Direct Command
```bash
go run main.go
```

## 📍 URLs
```
Server:  http://localhost:3000
Health:  http://localhost:3000/health
Ping:    http://localhost:3000/ping
```

## ⚙️ Configuration
```
File: .env.local (copy from .env.local.example)

Key Settings:
- DB_HOST=localhost
- DB_PORT=5432
- DB_USER=attendance_user
- DB_PASSWORD=attendance_password
- SMTP_USER=your-email@gmail.com
- SMTP_PASS=your-app-password
```

## 🗄️ Database Setup (First Time Only)
```bash
# Create database
psql -U postgres -c "CREATE DATABASE attendance_local;"

# Create user
psql -U postgres -c "CREATE USER attendance_user WITH PASSWORD 'attendance_password';"

# Grant privileges
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE attendance_local TO attendance_user;"
```

## 🧪 Test Endpoints

### Health Check
```bash
curl http://localhost:3000/health
```

### Register User
```bash
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@localhost.local",
    "password": "SecurePass123!",
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User",
    "course": "BSCS",
    "year_level": "1st Year"
  }'
```

### Resend Verification (Pending User)
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "test@localhost.local"}'

# Expected: 200 OK
```

### Resend Non-Existent Email
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "unknown@localhost.local"}'

# Expected: 404 Not Found
```

### Resend Already Verified User
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email": "verified@localhost.local"}'

# Expected: 409 Conflict
```

## 🗃️ Database Queries
```bash
# Connect to database
psql -U attendance_user -d attendance_local

# Check pending users
SELECT email, student_id, verification_code FROM pending_users;

# Check verified users
SELECT email, student_id, is_verified FROM users;

# Delete test data
DELETE FROM pending_users WHERE email LIKE '%localhost.local%';

# Exit
\q
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Port 3000 in use** | Change APP_PORT in .env.local or: `netstat -ano \| findstr :3000` |
| **DB connection fails** | Check PostgreSQL running: `psql -U postgres -c "SELECT 1;"` |
| **SMTP not sending** | Get Gmail App Password: https://myaccount.google.com/apppasswords |
| **Build fails** | Run: `go mod tidy` then `go mod download` |
| **Modules not found** | Run: `go mod tidy` |

## 📚 Documentation
```
LOCALHOST_SETUP.md    - Complete setup guide (read first)
LOCALHOST_TESTING.md  - Full testing guide with examples
LOCALHOST_READY.md    - What was done and current status
.env.local.example    - Configuration template
```

## ✅ Verification Checklist
- [ ] PostgreSQL installed/running
- [ ] .env.local created from .env.local.example
- [ ] Database created: `attendance_local`
- [ ] Database user: `attendance_user`
- [ ] SMTP configured with Gmail App Password
- [ ] Server starts: `go run main.go`
- [ ] Health check works: `curl http://localhost:3000/health`

## 🎯 Common Workflow
```
1. Edit .env.local with your credentials
2. Make sure PostgreSQL is running
3. Run: start-localhost.bat
4. Test: curl http://localhost:3000/health
5. Use Postman or cURL to test endpoints
6. Check database: psql -U attendance_user -d attendance_local
```

## 🚨 Important Notes
- ⚠️ Use Gmail App Password, NOT regular password
- ⚠️ Keep .env.local out of git (add to .gitignore)
- ⚠️ Don't commit .env.local to repository
- ✅ Use .env for production cloud database
- ✅ Use .env.local for local development

---

**Status**: ✅ Ready for Development  
**Last Updated**: January 14, 2026  
**All Systems**: Operational
