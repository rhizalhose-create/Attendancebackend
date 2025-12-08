# Backend Fixes for QR Code Data

## Issue
The `GetAllUsers` function in `controller/promote_controller.go` does not include `qr_code_data` in the response, causing the Flutter app to show "QR code not available".

## Fix 1: Update GetAllUsers to include qr_code_data

In `controller/promote_controller.go`, update the `GetAllUsers` function:

```go
// Get all users (for admin dashboard)
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
			"qr_code_data":  user.QRCodeData,  // ADD THIS LINE
			"qr_type":       user.QRType,       // ADD THIS LINE (optional)
			"profile_picture": user.ProfilePicture, // ADD THIS LINE (optional)
			"created_at":    user.CreatedAt,
			"verified_at":   user.VerifiedAt,
		})
	}

	return c.JSON(fiber.Map{
		"users": response,
		"count": len(response),
	})
}
```

## Fix 2: Add GetCurrentUser endpoint

Add this new function to `controller/promote_controller.go`:

```go
// GetCurrentUser returns the current authenticated user's data
func GetCurrentUser(c *fiber.Ctx) error {
	user, ok := c.Locals("user").(models.User)
	if !ok {
		// Try to get from Authorization header
		studentID := c.Get("Authorization")
		if studentID == "" {
			studentID = c.Get("X-Student-ID")
		}
		
		// Remove "Bearer " prefix if present
		if strings.HasPrefix(studentID, "Bearer ") {
			studentID = strings.TrimPrefix(studentID, "Bearer ")
		}
		
		if studentID == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Unauthorized",
			})
		}
		
		var dbUser models.User
		if err := connection.DB.Where("student_id = ?", studentID).First(&dbUser).Error; err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "User not found",
			})
		}
		user = dbUser
	}

	// Return user data with QR code
	return c.JSON(fiber.Map{
		"user": map[string]interface{}{
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
			"qr_code_data":   user.QRCodeData,  // Include QR code
			"qr_type":        user.QRType,
			"profile_picture": user.ProfilePicture,
			"created_at":     user.CreatedAt,
			"verified_at":    user.VerifiedAt,
		},
	})
}
```

## Fix 3: Add route for GetCurrentUser

In `API/auth_routes.go`, add the route:

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
		adminRoutes.Post("/promote", controller.PromoteUser)
	}
}
```

## Summary

1. Add `qr_code_data` to GetAllUsers response
2. Create GetCurrentUser function
3. Add `/users/me` route

After these changes, the Flutter app will be able to fetch user data with QR codes.

