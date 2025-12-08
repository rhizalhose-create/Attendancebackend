# Backend Login Response Requirements

## Issue
The frontend is showing "student" role even though the database has "admin" role. This happens when the backend login response doesn't include the user's role.

## Required Login Response Format

The backend `/login` endpoint MUST return the user's role in the response. Here are the supported formats:

### Format 1: User Object (Recommended)
```json
{
  "user": {
    "student_id": "12345",
    "email": "user@example.com",
    "username": "username",
    "first_name": "John",
    "last_name": "Doe",
    "role": "admin",  // ← REQUIRED: Must include role
    "is_verified": true,
    ...
  }
}
```

### Format 2: Direct Role Field
```json
{
  "student_id": "12345",
  "email": "user@example.com",
  "role": "admin",  // ← REQUIRED: Must include role
  ...
}
```

## Backend Code Example (Go)

In your login controller, make sure to include the role:

```go
func Login(c *fiber.Ctx) error {
    // ... authentication logic ...
    
    // After successful authentication, return user with role
    return c.JSON(fiber.Map{
        "user": fiber.Map{
            "student_id": user.StudentID,
            "email":      user.Email,
            "username":   user.Username,
            "first_name": user.FirstName,
            "last_name":  user.LastName,
            "role":       user.Role,  // ← IMPORTANT: Include role
            "is_verified": user.IsVerified,
            // ... other fields ...
        },
    })
}
```

## Role Values

The frontend expects these role values (case-insensitive):
- `"admin"` → Admin Dashboard
- `"superadmin"` → SuperAdmin Dashboard  
- `"student"` → Student Dashboard (default)

## Testing

To verify the backend is returning the role:

1. Test the login endpoint:
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"student_id": "YOUR_STUDENT_ID", "password": "YOUR_PASSWORD"}'
```

2. Check the response - it MUST include `"role": "admin"` (or your actual role)

3. If role is missing, update your backend login controller to include it.

## Frontend Behavior

The Flutter app will:
1. Extract role from login response
2. Use that role for navigation
3. If role is missing, it will try to fetch from `/users/me` or other endpoints
4. If all fails, it defaults to "student" role

**To fix the issue:** Make sure your backend login endpoint returns the `role` field in the response.

