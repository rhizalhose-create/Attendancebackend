package controller

import (
	"attendance-system/models"
	"attendance-system/services"
	"attendance-system/utils"
	"strings"

	"github.com/gofiber/fiber/v2"
)

const (
	failedFetchUserProfile    = "failed to fetch user profile"
	errorFailedGenerateAccessToken = "failed to generate access token"
	errorInvalidRequest       = "invalid request"
)

func Login(c *fiber.Ctx) error {
	req := new(models.LoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": errorInvalidRequest})
	}

	// Fetch user profile so caller gets the current role immediately
	// Determine lookup key (email vs student id)
	var user models.User
	if strings.Contains(req.StudentID, "@") {
		// login by email
		if err := services.GetUserByEmail(req.StudentID, &user); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": failedFetchUserProfile})
		}
	} else {
		sid := utils.SanitizeStudentID(req.StudentID)
		if err := services.GetUserByStudentID(sid, &user); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": failedFetchUserProfile})
		}
	}

	return c.JSON(fiber.Map{
		"message":    "Login successful",
		"student_id": user.StudentID,
		"role":       user.Role,
		"first_name": user.FirstName,
		"last_name":  user.LastName,
	})
}

// Optional: Add login by email endpoint
func LoginByEmail(c *fiber.Ctx) error {
	type EmailLoginRequest struct {
		Email          string `json:"email"`
		Password       string `json:"password"`
		RecaptchaToken string `json:"recaptcha_token,omitempty"`
	}

	req := new(EmailLoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": errorInvalidRequest})
	}

	// Get user by email
	var user models.User
	if err := services.GetUserByEmail(req.Email, &user); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": failedFetchUserProfile})
	}

	// TODO: Add password verification here
	// if !services.VerifyPassword(req.Password, user.PasswordHash) {
	//     return c.Status(401).JSON(fiber.Map{"error": "Invalid credentials"})
	// }

	accessToken, err := services.GenerateAccessToken(user)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": errorFailedGenerateAccessToken})
	}

	refreshToken, err := services.GenerateRefreshToken(user)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate refresh token"})
	}

	return c.JSON(fiber.Map{
		"message":       "Login successful",
		"email":         user.Email,
		"student_id":    user.StudentID,
		"role":          user.Role,
		"first_name":    user.FirstName,
		"last_name":     user.LastName,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

// RefreshToken generates a new access token from a valid refresh token
func RefreshToken(c *fiber.Ctx) error {
	type RefreshRequest struct {
		RefreshToken string `json:"refresh_token"`
	}

	req := new(RefreshRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": errorInvalidRequest})
	}

	if req.RefreshToken == "" {
		return c.Status(400).JSON(fiber.Map{"error": "refresh_token is required"})
	}

	// Verify refresh token
	claims, err := services.VerifyRefreshToken(req.RefreshToken)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired refresh token"})
	}

	// Get user
	var user models.User
	if err := services.GetUserByStudentID(claims.StudentID, &user); err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "User not found"})
	}

	// Generate new access token
	accessToken, err := services.GenerateAccessToken(user)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": errorFailedGenerateAccessToken})
	}

	return c.JSON(fiber.Map{
		"message":      "Token refreshed successfully",
		"access_token": accessToken,
	})
}

// GetProfile returns the authenticated user's profile
func GetProfile(c *fiber.Ctx) error {
	// Get user from context (set by RequireAuth middleware)
	user, ok := c.Locals("user").(models.User)
	if !ok {
		return c.Status(401).JSON(fiber.Map{"error": "Unauthorized"})
	}

	return c.JSON(fiber.Map{
		"student_id": user.StudentID,
		"email":      user.Email,
		"role":       user.Role,
		"first_name": user.FirstName,
		"last_name":  user.LastName,
	})
}