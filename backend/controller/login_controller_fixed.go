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

	// Return user with role - CRITICAL for frontend role-based navigation
	return c.JSON(fiber.Map{
		"message": "Login successful",
		"user": fiber.Map{
			"student_id":    user.StudentID,
			"email":         user.Email,
			"username":      user.Username,
			"first_name":    user.FirstName,
			"last_name":     user.LastName,
			"middle_name":   user.MiddleName,
			"role":          user.Role,  // ← CRITICAL: Include role for navigation
			"is_verified":   user.IsVerified,
			"course":        user.Course,
			"year_level":    user.YearLevel,
			"section":       user.Section,
			"department":    user.Department,
			"college":       user.College,
			"contact_number": user.ContactNumber,
			"address":       user.Address,
			"qr_code_data":  user.QRCodeData,
			"qr_type":       user.QRType,
			"profile_picture": user.ProfilePicture,
			"created_at":    user.CreatedAt,
			"verified_at":   user.VerifiedAt,
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

	// Return user with role - CRITICAL for frontend role-based navigation
	return c.JSON(fiber.Map{
		"message": "Login successful",
		"user": fiber.Map{
			"student_id":    user.StudentID,
			"email":         user.Email,
			"username":      user.Username,
			"first_name":    user.FirstName,
			"last_name":     user.LastName,
			"middle_name":   user.MiddleName,
			"role":          user.Role,  // ← CRITICAL: Include role for navigation
			"is_verified":   user.IsVerified,
			"course":        user.Course,
			"year_level":    user.YearLevel,
			"section":       user.Section,
			"department":    user.Department,
			"college":       user.College,
			"contact_number": user.ContactNumber,
			"address":       user.Address,
			"qr_code_data":  user.QRCodeData,
			"qr_type":       user.QRType,
			"profile_picture": user.ProfilePicture,
			"created_at":    user.CreatedAt,
			"verified_at":   user.VerifiedAt,
		},
	})
}

