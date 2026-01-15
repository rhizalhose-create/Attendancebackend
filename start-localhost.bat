@echo off
REM Attendance Backend - Localhost Quick Start
REM Run this script to start the backend server

cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     Attendance Backend - Localhost Quick Start            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check if .env.local exists
if not exist ".env.local" (
    echo ⚠️  .env.local not found!
    echo.
    echo 📝 Creating .env.local from .env.local.example...
    copy .env.local.example .env.local
    echo.
    echo ⚠️  Please edit .env.local with your database and SMTP credentials!
    echo.
    echo Edit these values in .env.local:
    echo   - DB_HOST: localhost
    echo   - DB_PORT: 5432
    echo   - DB_USER: attendance_user
    echo   - DB_PASSWORD: your_db_password
    echo   - SMTP_USER: your-email@gmail.com
    echo   - SMTP_PASS: your-app-password
    echo.
    pause
    exit /b 1
)

REM Check if Go is installed
go version >nul 2>&1
if errorlevel 1 (
    echo ❌ Go is not installed! Please install Go 1.19+
    echo Download from: https://golang.org/dl/
    pause
    exit /b 1
)

echo ✅ Go found!
echo.

REM Check if database is running
echo 🔍 Checking database connection...
psql -U attendance_user -d attendance_local -c "SELECT 1" >nul 2>&1
if errorlevel 1 (
    echo ⚠️  ⚠️  Could not connect to database!
    echo.
    echo 📋 Make sure PostgreSQL is running:
    echo   1. Start PostgreSQL service (usually runs automatically)
    echo   2. Create database with:
    echo      psql -U postgres -c "CREATE DATABASE attendance_local;"
    echo   3. Create user with:
    echo      psql -U postgres -c "CREATE USER attendance_user WITH PASSWORD 'attendance_password';"
    echo   4. Grant privileges with:
    echo      psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE attendance_local TO attendance_user;"
    echo.
    echo 🐳 Or use Docker:
    echo   docker run --name postgres-attendance -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=attendance_local -p 5432:5432 -d postgres:15
    echo.
    echo After setting up database, run this script again.
    pause
    exit /b 1
)

echo ✅ Database connection successful!
echo.

REM Install dependencies
echo 📦 Installing Go dependencies...
go mod tidy
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed!
echo.

REM Start server
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║         🚀 Starting Attendance Backend Server...          ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📌 Server will run on:
echo    🌍 http://localhost:3000
echo    💚 Health: http://localhost:3000/health
echo    📡 Ping:   http://localhost:3000/ping
echo.
echo 📝 Press Ctrl+C to stop the server
echo.

go run main.go

pause
