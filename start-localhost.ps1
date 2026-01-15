#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Attendance Backend - Localhost Quick Start Script
    
.DESCRIPTION
    This script starts the Attendance Backend on localhost.
    It checks for required dependencies and configuration before starting.
#>

$ErrorActionPreference = "Stop"

function Write-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Attendance Backend - Localhost Quick Start            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Check-EnvFile {
    if (-not (Test-Path ".env.local")) {
        Write-Host "⚠️  .env.local not found!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📝 Creating .env.local from template..." -ForegroundColor Green
        
        if (Test-Path ".env.local.example") {
            Copy-Item ".env.local.example" ".env.local"
            Write-Host "✅ .env.local created!" -ForegroundColor Green
        } else {
            Write-Host "❌ .env.local.example not found!" -ForegroundColor Red
            Write-Host "Please create .env.local manually with your configuration." -ForegroundColor Red
            exit 1
        }
        
        Write-Host ""
        Write-Host "⚠️  Please edit .env.local with your credentials:" -ForegroundColor Yellow
        Write-Host "   - DB_HOST: localhost" -ForegroundColor Gray
        Write-Host "   - DB_PORT: 5432" -ForegroundColor Gray
        Write-Host "   - DB_USER: attendance_user" -ForegroundColor Gray
        Write-Host "   - DB_PASSWORD: your_db_password" -ForegroundColor Gray
        Write-Host "   - SMTP_USER: your-email@gmail.com" -ForegroundColor Gray
        Write-Host "   - SMTP_PASS: your-app-password" -ForegroundColor Gray
        Write-Host ""
        
        # Open editor
        Write-Host "Opening .env.local in editor..." -ForegroundColor Green
        & code .env.local
        
        Write-Host "⏸️  Press any key when you're done editing .env.local..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Check-Go {
    Write-Host "🔍 Checking Go installation..." -ForegroundColor Cyan
    
    try {
        $goVersion = go version
        Write-Host "✅ $goVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Go not found!" -ForegroundColor Red
        Write-Host "Please install Go 1.19+ from: https://golang.org/dl/" -ForegroundColor Yellow
        exit 1
    }
}

function Check-Database {
    Write-Host ""
    Write-Host "🔍 Checking database connection..." -ForegroundColor Cyan
    
    # Load env file
    Get-Content .env.local | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
    
    $dbHost = [Environment]::GetEnvironmentVariable("DB_HOST") -or "localhost"
    $dbPort = [Environment]::GetEnvironmentVariable("DB_PORT") -or "5432"
    $dbUser = [Environment]::GetEnvironmentVariable("DB_USER") -or "attendance_user"
    $dbName = [Environment]::GetEnvironmentVariable("DB_NAME") -or "attendance_local"
    
    try {
        $result = psql -h $dbHost -U $dbUser -d $dbName -c "SELECT 1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database connection successful!" -ForegroundColor Green
            return $true
        }
    }
    catch { }
    
    Write-Host "⚠️  Could not connect to database!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Make sure PostgreSQL is running:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Local PostgreSQL" -ForegroundColor Cyan
    Write-Host "  1. Start PostgreSQL service" -ForegroundColor Gray
    Write-Host "  2. Create database:" -ForegroundColor Gray
    Write-Host "     psql -U postgres -c ""CREATE DATABASE attendance_local;""" -ForegroundColor Gray
    Write-Host "  3. Create user:" -ForegroundColor Gray
    Write-Host "     psql -U postgres -c ""CREATE USER attendance_user WITH PASSWORD 'attendance_password';""" -ForegroundColor Gray
    Write-Host "  4. Grant privileges:" -ForegroundColor Gray
    Write-Host "     psql -U postgres -c ""GRANT ALL PRIVILEGES ON DATABASE attendance_local TO attendance_user;""" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Docker" -ForegroundColor Cyan
    Write-Host "  docker run --name postgres-attendance -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=attendance_local -p 5432:5432 -d postgres:15" -ForegroundColor Gray
    Write-Host ""
    
    $continue = Read-Host "Continue anyway? (y/n)"
    return $continue -eq "y"
}

function Install-Dependencies {
    Write-Host ""
    Write-Host "📦 Installing Go dependencies..." -ForegroundColor Cyan
    
    try {
        go mod tidy
        Write-Host "✅ Dependencies installed!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install dependencies!" -ForegroundColor Red
        Write-Host $_.Exception.Message
        exit 1
    }
}

function Start-Server {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║      🚀 Starting Attendance Backend Server...             ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "📌 Server running on:" -ForegroundColor Cyan
    Write-Host "   🌍 http://localhost:3000" -ForegroundColor Green
    Write-Host "   💚 Health: http://localhost:3000/health" -ForegroundColor Green
    Write-Host "   📡 Ping:   http://localhost:3000/ping" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    & go run main.go
}

# Main execution
Clear-Host
Write-Header
Check-EnvFile
Check-Go
$dbOk = Check-Database

if ($dbOk) {
    Install-Dependencies
    Start-Server
} else {
    Write-Host "❌ Setup incomplete. Please fix the database connection and try again." -ForegroundColor Red
}
