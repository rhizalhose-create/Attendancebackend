# Verification Code Resend - Testing Guide

## Quick Test Commands (cURL)

### Test 1: Resend to Valid Pending User ✅
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"tazamandy@gmail.com"}'

# Expected Response (200 OK):
{
  "message": "Verification code resent successfully. Please check your email.",
  "student_id": "260114-XXXX",
  "token": "eyJhbGc...",
  "status": "success"
}
```

### Test 2: Resend to Already Verified User ⚠️
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"verified-user@gmail.com"}'

# Expected Response (409 Conflict):
{
  "error": "user is already verified. Please login to your account",
  "status": "already_verified"
}
```

### Test 3: Resend to Non-Existent Email ❌
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"unknown@gmail.com"}'

# Expected Response (404 Not Found):
{
  "error": "email not found. Please check if you registered with this email",
  "status": "not_found"
}
```

### Test 4: Empty Email Request ❌
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email":""}'

# Expected Response (400 Bad Request):
{
  "error": "Email is required"
}
```

---

## Complete Flow Test (All Steps)

### Step 1: Register New User
```bash
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test-user@gmail.com",
    "password": "SecurePass123!",
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User",
    "course": "BS Computer Science",
    "year_level": "2nd Year",
    "department": "College of Science",
    "college": "CCS"
  }'

# Response: Get student_id and verification token
# Save these for later steps
```

### Step 2: Resend Verification Code (Without Verifying Yet)
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@gmail.com"}'

# Response: Get NEW verification code and token
# (Old code is invalidated, new one is sent via email)
```

### Step 3: Verify Email
```bash
# Extract the verification code from email or use the one from registration
# Using the token from Step 1 or Step 2:

curl -X POST http://localhost:3000/verify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token-from-step-2>" \
  -d '{"code":"123456"}'

# Response (200 OK):
{
  "message": "Email verification successful",
  "status": "success"
}

# Now user is in Users table, no longer in PendingUser table
```

### Step 4: Try Resending Again (User Already Verified)
```bash
curl -X POST http://localhost:3000/resend-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@gmail.com"}'

# Response (409 Conflict):
{
  "error": "user is already verified. Please login to your account",
  "status": "already_verified"
}

# ✅ This is the CORRECT behavior now!
```

---

## Postman Collection Test Cases

### Setup in Postman

1. Create Environment Variable:
   - Variable: `base_url` = `http://localhost:3000`
   - Variable: `verification_token` = (will be set by tests)

2. Add these test cases to your collection:

#### Test Case: Resend Verification - Valid Email
```javascript
// Test tab
pm.test("Status code is 200", function() {
    pm.expect(pm.response.code).to.be.oneOf([200]);
});

pm.test("Response has token", function() {
    var jsonData = pm.response.json();
    pm.expect(jsonData.token).to.exist;
    pm.environment.set("verification_token", jsonData.token);
});

pm.test("Response has student_id", function() {
    var jsonData = pm.response.json();
    pm.expect(jsonData.student_id).to.exist;
});
```

#### Test Case: Resend Verification - Already Verified
```javascript
// Test tab
pm.test("Status code is 409", function() {
    pm.expect(pm.response.code).to.equal(409);
});

pm.test("Response indicates already verified", function() {
    var jsonData = pm.response.json();
    pm.expect(jsonData.status).to.equal("already_verified");
});
```

#### Test Case: Resend Verification - Not Found
```javascript
// Test tab
pm.test("Status code is 404", function() {
    pm.expect(pm.response.code).to.equal(404);
});

pm.test("Response indicates not found", function() {
    var jsonData = pm.response.json();
    pm.expect(jsonData.status).to.equal("not_found");
});
```

---

## Frontend JavaScript Implementation

### Example: React Hook for Resend Verification

```javascript
import { useState } from 'react';

export const useResendVerification = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const resendCode = async (email) => {
    setLoading(true);
    setError(null);
    setSuccess(false);

    try {
      const response = await fetch('/resend-verification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
      });

      const data = await response.json();

      switch (response.status) {
        case 200:
          setSuccess(true);
          setError(null);
          // Save new token if verification not complete
          if (data.token) {
            localStorage.setItem('verificationToken', data.token);
          }
          return { success: true, data };

        case 404:
          setError('Email not found. Please register first.');
          return { success: false, action: 'redirect_to_register' };

        case 409:
          setError('Email already verified. Please login.');
          return { success: false, action: 'redirect_to_login' };

        case 500:
          setError('Failed to send email. Please try again later.');
          return { success: false };

        default:
          setError(data.error || 'An error occurred');
          return { success: false };
      }
    } catch (error) {
      setError('Network error. Please check your connection.');
      return { success: false };
    } finally {
      setLoading(false);
    }
  };

  return { resendCode, loading, error, success };
};
```

### Usage in Component

```javascript
function VerificationComponent({ email }) {
  const { resendCode, loading, error, success } = useResendVerification();
  const [showResendButton, setShowResendButton] = useState(false);
  const [countdown, setCountdown] = useState(0);

  const handleResendClick = async () => {
    const result = await resendCode(email);
    
    if (result.success) {
      showNotification('Code resent! Check your email', 'success');
      // Reset timer: can resend again in 60 seconds
      setCountdown(60);
    } else if (result.action === 'redirect_to_login') {
      showNotification(error, 'info');
      // Redirect to login page
      window.location.href = '/login';
    } else if (result.action === 'redirect_to_register') {
      showNotification(error, 'warning');
      // Redirect to register page
      window.location.href = '/register';
    } else {
      showNotification(error, 'error');
    }
  };

  // Countdown timer
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  return (
    <div className="verification-form">
      {success && (
        <div className="success-message">
          ✅ Verification code sent to {email}
        </div>
      )}
      
      {error && (
        <div className="error-message">
          ❌ {error}
        </div>
      )}

      <button
        onClick={handleResendClick}
        disabled={loading || countdown > 0}
        className="resend-button"
      >
        {loading ? 'Sending...' : ''}
        {countdown > 0 ? `Resend in ${countdown}s` : 'Resend Code'}
      </button>
    </div>
  );
}
```

---

## Troubleshooting

### Issue: "SMTP ERROR: Failed to send email"
**Solution**: Check SMTP configuration
```bash
# Verify environment variables are set
echo $SMTP_HOST
echo $SMTP_USER
echo $SMTP_PASS
echo $SMTP_PORT

# For Gmail, must use App Password, not regular password
# Get it from: https://myaccount.google.com/apppasswords
```

### Issue: Always getting 404 "email not found"
**Check**:
1. Did the user complete registration? Check if email is in `pending_users` table
2. Database connection working?
3. Email address typo? (Case-sensitive issues?)

### Issue: Always getting 409 "already verified"
**This is actually correct behavior!** This means:
1. User already verified their email
2. User should login, not try to resend code
3. If user forgot password, use `/forgot-password` endpoint instead

---

## Backend Logs to Watch

When testing, watch the backend logs for these messages:

### Success Log
```
📧 AuthService.resendVerificationCode called for tazamandy@gmail.com
✅ Verification email resent successfully to tazamandy@gmail.com
```

### Error Logs
```
📧 AuthService.resendVerificationCode called for tazamandy@gmail.com
❌ Failed to resend verification email to tazamandy@gmail.com: SMTP ERROR: ...
```

These logs match the error messages from the user's issue, confirming the fix is working.

---

## Summary of Changes

✅ **Backend now correctly handles**:
- Users not yet verified → Resend code (200)
- Users already verified → Clear message (409)
- Users never registered → Clear message (404)
- Email sending fails → Clear error (500)

✅ **Frontend can now**:
- Distinguish between different error scenarios
- Provide appropriate user guidance
- Redirect users to correct page (login/register)
- Show helpful error messages

🎉 **System is now fully functional!**
