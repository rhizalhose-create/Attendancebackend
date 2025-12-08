# Backend Connection Guide for Physical Device

## Problem: "Cannot connect to server" on Physical Phone

### Step 1: Verify Backend Server is Running

1. Check if your Go backend server is running:
   ```bash
   # In your backend directory
   go run main.go
   # or
   ./your-backend-executable
   ```

2. The server should show something like:
   ```
   Server running on port 3000
   ```

### Step 2: Check Backend Server Configuration

**IMPORTANT:** Your Go backend MUST listen on `0.0.0.0:3000` (not `localhost:3000`)

In your Go backend `main.go` or server file, make sure it's configured like this:

```go
// ✅ CORRECT - This allows connections from network
app.Listen("0.0.0.0:3000")

// ❌ WRONG - This only allows localhost connections
app.Listen("localhost:3000")
// or
app.Listen("127.0.0.1:3000")
```

### Step 3: Check Your Computer's IP Address

1. Open Command Prompt or PowerShell
2. Run: `ipconfig | findstr IPv4`
3. Note your IP address (e.g., `192.168.1.13`)
4. Update `lib/services/api_service.dart` with this IP:
   ```dart
   static const String baseUrl = 'http://192.168.1.13:3000';
   ```

### Step 4: Test Connection from Computer

1. Open browser on your computer
2. Go to: `http://192.168.1.13:3000` (use your IP)
3. You should see a response from the backend
4. If you get "connection refused" or timeout, the backend is not accessible

### Step 5: Check Firewall Settings

**Windows Firewall:**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter port `3000`
6. Allow the connection
7. Apply to all profiles
8. Name it "Backend Server Port 3000"

**Or temporarily disable firewall for testing:**
- Go to Windows Security → Firewall & network protection
- Turn off firewall (for testing only)

### Step 6: Verify Same Network

1. Make sure your phone and computer are on the **SAME Wi-Fi network**
2. Check phone Wi-Fi settings
3. Check computer network connection
4. They must be on the same network (e.g., both on "Home Wi-Fi")

### Step 7: Test from Phone Browser

1. On your phone, open a web browser
2. Go to: `http://192.168.1.13:3000` (use your computer's IP)
3. If this works, the connection is good
4. If this doesn't work, check Steps 1-6 again

### Step 8: Update Flutter App

After fixing backend, rebuild the Flutter app:
```bash
flutter clean
flutter pub get
flutter run -d "YOUR_DEVICE_NAME"
```

## Quick Checklist

- [ ] Backend server is running
- [ ] Backend listens on `0.0.0.0:3000` (not localhost)
- [ ] Computer IP address is correct in `api_service.dart`
- [ ] Firewall allows port 3000
- [ ] Phone and computer on same Wi-Fi network
- [ ] Can access `http://YOUR_IP:3000` from phone browser
- [ ] Flutter app rebuilt after changes

## Common Issues

1. **Backend only listening on localhost**
   - Fix: Change to `0.0.0.0:3000` in Go code

2. **Firewall blocking connections**
   - Fix: Allow port 3000 in firewall or disable temporarily

3. **Wrong IP address**
   - Fix: Check IP with `ipconfig` and update `api_service.dart`

4. **Different networks**
   - Fix: Connect both devices to same Wi-Fi

5. **Backend not running**
   - Fix: Start the backend server

## Testing the Connection

You can test if the backend is accessible by running this in your phone's browser:
```
http://192.168.1.13:3000
```

If you see a response (even an error page), the connection works!
If you see "connection refused" or timeout, check the steps above.

