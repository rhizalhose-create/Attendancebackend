# Complete Backend Fixes

## Critical Fixes Required

### 1. Fix Login Controller - Return User Role ✅ CRITICAL

**File: `controller/login_controller.go`**

**Current Code (WRONG):**
```go
func Login(c *fiber.Ctx) error {
	req := new(models.LoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if err := services.LoginService(*req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"message": "Login successful",
		"student_id": req.StudentID,
	})
}
```

**Fixed Code (CORRECT):**
```go
package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"attendance-system/services"
	"github.com/gofiber/fiber/v2"
)

func Login(c *fiber.Ctx) error {
	req := new(models.LoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if err := services.LoginService(*req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	// Fetch user to get role and other details
	var user models.User
	if err := connection.DB.Where("student_id = ?", req.StudentID).First(&user).Error; err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "User not found"})
	}

	// Return user with role
	return c.JSON(fiber.Map{
		"message": "Login successful",
		"user": fiber.Map{
			"student_id":  user.StudentID,
			"email":       user.Email,
			"username":    user.Username,
			"first_name":  user.FirstName,
			"last_name":   user.LastName,
			"role":        user.Role,  // ← CRITICAL: Include role
			"is_verified": user.IsVerified,
			"course":      user.Course,
			"year_level":  user.YearLevel,
			"section":     user.Section,
			"qr_code_data": user.QRCodeData,
		},
	})
}

func LoginByEmail(c *fiber.Ctx) error {
	type EmailLoginRequest struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	req := new(EmailLoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if err := services.LoginByEmailService(req.Email, req.Password); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	// Fetch user to get role and other details
	var user models.User
	if err := connection.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "User not found"})
	}

	// Return user with role
	return c.JSON(fiber.Map{
		"message": "Login successful",
		"user": fiber.Map{
			"student_id":  user.StudentID,
			"email":       user.Email,
			"username":    user.Username,
			"first_name":  user.FirstName,
			"last_name":   user.LastName,
			"role":        user.Role,  // ← CRITICAL: Include role
			"is_verified": user.IsVerified,
			"course":      user.Course,
			"year_level":  user.YearLevel,
			"section":     user.Section,
			"qr_code_data": user.QRCodeData,
		},
	})
}
```

### 2. Add GetCurrentUser Endpoint ✅ REQUIRED

**File: `controller/promote_controller.go` (add this function)**

```go
// GetCurrentUser returns the current authenticated user's data
func GetCurrentUser(c *fiber.Ctx) error {
	user, ok := c.Locals("user").(models.User)
	if !ok {
		// Fallback: try to get from Authorization header
		studentID, err := extractStudentIDFromHeader(c)
		if err != nil {
			return c.Status(401).JSON(fiber.Map{"error": "Unauthorized"})
		}
		
		var dbUser models.User
		if err := connection.DB.Where("student_id = ?", studentID).First(&dbUser).Error; err != nil {
			return c.Status(401).JSON(fiber.Map{"error": "User not found"})
		}
		user = dbUser
	}

	// Return safe user data (without password)
	return c.JSON(fiber.Map{
		"user": fiber.Map{
			"student_id":    user.StudentID,
			"email":         user.Email,
			"username":      user.Username,
			"first_name":    user.FirstName,
			"last_name":     user.LastName,
			"middle_name":   user.MiddleName,
			"role":          user.Role,
			"is_verified":   user.IsVerified,
			"course":        user.Course,
			"year_level":    user.YearLevel,
			"section":       user.Section,
			"department":    user.Department,
			"college":       user.College,
			"contact_number": user.ContactNumber,
			"address":       user.Address,
			"qr_code_data":  user.QRCodeData,  // ← Include QR code data
			"qr_type":       user.QRType,
			"profile_picture": user.ProfilePicture,
			"created_at":    user.CreatedAt,
			"verified_at":   user.VerifiedAt,
		},
	})
}

// Helper function to extract student ID from header
func extractStudentIDFromHeader(c *fiber.Ctx) (string, error) {
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return "", fiber.NewError(401, "Authorization required")
	}
	
	parts := strings.Split(authHeader, " ")
	if len(parts) == 2 && parts[0] == "Bearer" {
		return parts[1], nil
	}
	
	return "", fiber.NewError(401, "Invalid authorization format")
}
```

### 3. Fix GetAllUsers - Include QR Code Data ✅ REQUIRED

**File: `controller/promote_controller.go`**

**Current Code (MISSING qr_code_data):**
```go
func GetAllUsers(c *fiber.Ctx) error {
	// ... existing code ...
	response = append(response, map[string]interface{}{
		"student_id":  user.StudentID,
		"email":       user.Email,
		// ... missing qr_code_data
	})
}
```

**Fixed Code:**
```go
func GetAllUsers(c *fiber.Ctx) error {
	db := connection.DB
	var users []models.User
	if err := db.Find(&users).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch users",
		})
	}

	// Create safe response (without passwords)
	var response []map[string]interface{}
	for _, user := range users {
		response = append(response, map[string]interface{}{
			"student_id":     user.StudentID,
			"email":          user.Email,
			"username":       user.Username,
			"first_name":     user.FirstName,
			"last_name":      user.LastName,
			"middle_name":    user.MiddleName,
			"role":           user.Role,
			"is_verified":    user.IsVerified,
			"course":         user.Course,
			"year_level":     user.YearLevel,
			"section":        user.Section,
			"department":     user.Department,
			"college":        user.College,
			"contact_number": user.ContactNumber,
			"address":        user.Address,
			"qr_code_data":   user.QRCodeData,  // ← ADD THIS
			"qr_type":        user.QRType,       // ← ADD THIS
			"profile_picture": user.ProfilePicture, // ← ADD THIS
			"created_at":     user.CreatedAt,
			"verified_at":    user.VerifiedAt,
		})
	}

	return c.JSON(fiber.Map{
		"users": response,
		"count": len(response),
	})
}
```

### 4. Add GetUserByStudentID Endpoint ✅ REQUIRED

**File: `controller/promote_controller.go` (add this function)**

```go
// GetUserByStudentID returns a specific user by student ID (admin/superadmin only)
func GetUserByStudentID(c *fiber.Ctx) error {
	studentID := c.Params("student_id")
	if studentID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Student ID is required"})
	}

	var user models.User
	if err := connection.DB.Where("student_id = ?", studentID).First(&user).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "User not found"})
	}

	// Return safe user data (without password)
	return c.JSON(fiber.Map{
		"user": fiber.Map{
			"student_id":     user.StudentID,
			"email":          user.Email,
			"username":       user.Username,
			"first_name":     user.FirstName,
			"last_name":      user.LastName,
			"middle_name":    user.MiddleName,
			"role":           user.Role,
			"is_verified":    user.IsVerified,
			"course":         user.Course,
			"year_level":     user.YearLevel,
			"section":        user.Section,
			"department":     user.Department,
			"college":        user.College,
			"contact_number": user.ContactNumber,
			"address":        user.Address,
			"qr_code_data":   user.QRCodeData,  // ← Include QR code data
			"qr_type":        user.QRType,
			"profile_picture": user.ProfilePicture,
			"created_at":     user.CreatedAt,
			"verified_at":    user.VerifiedAt,
		},
	})
}
```

### 5. Update Auth Routes - Add /users/me ✅ REQUIRED

**File: `API/auth_routes.go`**

**Current Code:**
```go
func AuthRoutes(app *fiber.App) {
	// Public routes
	app.Post("/register", controller.Register)
	app.Post("/login", controller.Login)
	app.Post("/login/email", controller.LoginByEmail)
	app.Post("/verify", controller.VerifyEmail)

	// Password reset routes
	app.Post("/forgot-password", controller.ForgotPassword)
	app.Post("/reset-password", controller.ResetPassword)
	app.Post("/resend-reset-code", controller.ResendCode)

	// Admin routes (require superadmin)
	adminRoutes := app.Group("/admin", middleware.RequireSuperAdmin)
	{
		adminRoutes.Get("/users", controller.GetAllUsers)
		adminRoutes.Post("/promote", controller.PromoteUser)
	}
}
```

**Fixed Code:**
```go
func AuthRoutes(app *fiber.App) {
	// Public routes
	app.Post("/register", controller.Register)
	app.Post("/login", controller.Login)
	app.Post("/login/email", controller.LoginByEmail)
	app.Post("/verify", controller.VerifyEmail)

	// Password reset routes
	app.Post("/forgot-password", controller.ForgotPassword)
	app.Post("/reset-password", controller.ResetPassword)
	app.Post("/resend-reset-code", controller.ResendCode)

	// Get current user (requires auth)
	app.Get("/users/me", middleware.RequireAuth, controller.GetCurrentUser)

	// Admin routes (require superadmin)
	adminRoutes := app.Group("/admin", middleware.RequireSuperAdmin)
	{
		adminRoutes.Get("/users", controller.GetAllUsers)
		adminRoutes.Get("/users/:student_id", controller.GetUserByStudentID)  // ← ADD THIS
		adminRoutes.Post("/promote", controller.PromoteUser)
	}
}
```

### 6. Fix MarkAttendance Response - Include Student Name ✅ REQUIRED

**File: `controller/attendance_controller.go`**

The `MarkAttendance` function should already return the student in the attendance object (from `services.MarkAttendance`), but let's ensure it's properly formatted:

**Current Code:**
```go
attendance, err := services.MarkAttendance(*req, user.StudentID, user.Role)
if err != nil {
	return c.Status(400).JSON(fiber.Map{"error": err.Error()})
}

return c.Status(201).JSON(fiber.Map{
	"message":    "Attendance marked successfully",
	"attendance": attendance,
})
```

**This should already work** if `services.MarkAttendance` returns attendance with `Student` populated. The service code shows it does:
```go
attendance.Student = student
return &attendance, nil
```

So the response should already include student name. If not, verify the service is returning it correctly.

### 7. Security Improvements ✅ RECOMMENDED

**File: `middleware/security.go`**

**Current Code:**
```go
func SecurityHeaders(c *fiber.Ctx) error {
	c.Set("X-Frame-Options", "DENY")
	c.Set("X-Content-Type-Options", "nosniff")
	c.Set("X-XSS-Protection", "1; mode=block")
	c.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
	c.Set("Content-Security-Policy", "default-src 'self'")
	c.Set("Referrer-Policy", "strict-origin-when-cross-origin")
	c.Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
	return c.Next()
}
```

**Improved Code (More Secure):**
```go
package middleware

import (
	"github.com/gofiber/fiber/v2"
)

// SecurityHeaders adds comprehensive security headers
func SecurityHeaders(c *fiber.Ctx) error {
	// Prevent clickjacking
	c.Set("X-Frame-Options", "DENY")
	
	// Prevent MIME type sniffing
	c.Set("X-Content-Type-Options", "nosniff")
	
	// Enable XSS protection
	c.Set("X-XSS-Protection", "1; mode=block")
	
	// Enforce HTTPS in production
	c.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
	
	// Content Security Policy - More permissive for API
	c.Set("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' *;")
	
	// Referrer Policy
	c.Set("Referrer-Policy", "strict-origin-when-cross-origin")
	
	// Permissions Policy
	c.Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
	
	// Additional security headers
	c.Set("X-Permitted-Cross-Domain-Policies", "none")
	c.Set("X-Download-Options", "noopen")
	c.Set("X-DNS-Prefetch-Control", "off")
	
	return c.Next()
}
```

### 8. Fix Main.go - Listen on 0.0.0.0 ✅ CRITICAL

**File: `main.go`**

**Current Code:**
```go
app.Listen(":" + port)
```

**Fixed Code:**
```go
// Listen on all interfaces (0.0.0.0) to allow connections from network
app.Listen("0.0.0.0:" + port)
```

This is CRITICAL for physical device connections!

## Summary of Changes

1. ✅ **Login Controller** - Return user with role in response
2. ✅ **LoginByEmail Controller** - Return user with role in response  
3. ✅ **GetCurrentUser** - New endpoint `/users/me`
4. ✅ **GetAllUsers** - Include `qr_code_data` in response
5. ✅ **GetUserByStudentID** - New endpoint `/admin/users/:student_id`
6. ✅ **Auth Routes** - Add `/users/me` route
7. ✅ **Main.go** - Listen on `0.0.0.0:3000` instead of `:3000`
8. ✅ **Security Headers** - Improved security headers

## Testing Checklist

After making these changes:

1. ✅ Test login - should return user with role
2. ✅ Test `/users/me` - should return current user with qr_code_data
3. ✅ Test `/admin/users` - should include qr_code_data
4. ✅ Test `/admin/users/:student_id` - should return specific user
5. ✅ Test from physical device - should connect to `0.0.0.0:3000`
6. ✅ Test role-based navigation - admin → admin dashboard

## Important Notes

- **Restart backend server** after making changes
- **Clear Flutter app cache** if needed: `flutter clean && flutter pub get`
- **Verify backend is listening on 0.0.0.0:3000** (not localhost)
- **Check firewall** allows port 3000

