package middleware

import (
	"attendance-system/connection"
	"attendance-system/models"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// extractStudentID extracts student ID from Authorization header
func extractStudentID(c *fiber.Ctx) (string, error) {
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		// Try alternative header
		authHeader = c.Get("X-Student-ID")
		if authHeader == "" {
			return "", fiber.NewError(fiber.StatusUnauthorized, "Authorization required")
		}
		// Set as Bearer format for consistency
		authHeader = "Bearer " + authHeader
	}

	// Extract StudentID from "Bearer {student_id}"
	parts := strings.Split(authHeader, " ")
	var studentID string
	if len(parts) == 2 && parts[0] == "Bearer" {
		studentID = parts[1]
	} else if len(parts) == 1 {
		studentID = parts[0]
	} else {
		return "", fiber.NewError(fiber.StatusUnauthorized, "Invalid authorization format. Use: Bearer {student_id}")
	}

	if studentID == "" {
		return "", fiber.NewError(fiber.StatusUnauthorized, "Student ID is required")
	}

	return studentID, nil
}

func RequireSuperAdmin(c *fiber.Ctx) error {
	studentID, err := extractStudentID(c)
	if err != nil {
		return err
	}

	// Find user
	var user models.User
	if err := connection.DB.Where("student_id = ?", studentID).First(&user).Error; err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid credentials",
		})
	}

	// Check if user is superadmin
	if user.Role != "superadmin" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Access denied",
		})
	}

	// Store user info in context for later use
	c.Locals("user", user)

	return c.Next()
}

// RequireAuth - Basic authentication middleware (checks if user exists and is verified)
func RequireAuth(c *fiber.Ctx) error {
	studentID, err := extractStudentID(c)
	if err != nil {
		return err
	}

	// Find user
	var user models.User
	if err := connection.DB.Where("student_id = ?", studentID).First(&user).Error; err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid credentials",
		})
	}

	// Check if user is verified
	if !user.IsVerified {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Account not verified. Please verify your email first.",
		})
	}

	// Store user info in context
	c.Locals("user", user)

	return c.Next()
}

// RequireFacultyOrAdmin - Requires faculty, admin, or superadmin role
func RequireFacultyOrAdmin(c *fiber.Ctx) error {
	user, ok := c.Locals("user").(models.User)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Authentication required",
		})
	}

	validRoles := map[string]bool{
		"superadmin": true,
		"admin":      true,
		"faculty":    true,
	}

	if !validRoles[user.Role] {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Only faculty, admin, or superadmin can perform this action",
		})
	}

	return c.Next()
}
