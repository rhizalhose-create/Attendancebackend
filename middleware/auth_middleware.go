package middleware

import (
	"attendance-system/connection"
	"attendance-system/models"
	"github.com/gofiber/fiber/v2"
	"strings"
)

func RequireSuperAdmin(c *fiber.Ctx) error {
	// Get Authorization header
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Authorization header required",
		})
	}

	// Extract StudentID from "Bearer {student_id}"
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid authorization format. Use: Bearer {student_id}",
		})
	}

	studentID := parts[1]

	// Find user
	var user models.User
	if err := connection.DB.Where("student_id = ?", studentID).First(&user).Error; err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	// Check if user is superadmin
	if user.Role != "superadmin" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Only superadmin can perform this action",
		})
	}

	// Store user info in context for later use
	c.Locals("user", user)
	
	return c.Next()
}