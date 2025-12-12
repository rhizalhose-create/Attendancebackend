// controller/password_controller.go
package controller

import (
	"attendance-system/models"
	"attendance-system/services"
	"attendance-system/utils"

	"github.com/gofiber/fiber/v2"
)

const (
	ErrInvalidRequest    = "Invalid request"
	ErrEmailRequired     = "Email is required"
	ErrCodeRequired      = "Code is required"
	ErrPasswordRequired  = "Password is required"
	ErrAllFieldsRequired = "All fields are required"
	SuccessResetCodeSent = "If your email is registered, you will receive a reset code."
	SuccessCodeValid     = "Code is valid"
	SuccessPasswordReset = "Password reset successful"
	SuccessNewCodeSent   = "New code sent if email is registered"
)

// ForgotPassword - Request reset code
func ForgotPassword(c *fiber.Ctx) error {

	req := new(models.ResetPasswordRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": ErrInvalidRequest})
	}

	// Always return success (security)
	_, err := services.ForgotPassword(req.Email)
	if err != nil {
		// Log error without exposing sensitive information
		// Error is already handled in service layer
	}

	return c.JSON(fiber.Map{
		"message": SuccessResetCodeSent,
		"status":  "success",
	})
}

func ResetPassword(c *fiber.Ctx) error {
	req := new(models.ResetPasswordRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": ErrInvalidRequest})
	}

	if req.Email == "" || req.Code == "" || req.NewPassword == "" {
		return c.Status(400).JSON(fiber.Map{"error": ErrAllFieldsRequired})
	}

	// Validate password strength using same rules as registration
	if valid, msg := utils.ValidatePassword(req.NewPassword); !valid {
		return c.Status(400).JSON(fiber.Map{"error": msg})
	}

	err := services.ResetPasswordWithCode(req.Email, req.Code, req.NewPassword)
	if err != nil {
		if err.Error() == "invalid or expired reset code" {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid or expired code"})
		}
		return c.Status(500).JSON(fiber.Map{"error": "Failed to reset password"})
	}

	return c.JSON(fiber.Map{
		"message": SuccessPasswordReset,
		"status":  "success",
	})
}

func ResendCode(c *fiber.Ctx) error {
	type Request struct {
		Email string `json:"email"`
	}

	req := new(Request)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": ErrInvalidRequest})
	}

	if req.Email == "" {
		return c.Status(400).JSON(fiber.Map{"error": ErrEmailRequired})
	}

	_, err := services.ResendResetCode(req.Email)
	if err != nil {
		// Log error without exposing sensitive information
		// Error is already handled in service layer
	}

	return c.JSON(fiber.Map{
		"message": SuccessNewCodeSent,
		"status":  "success",
	})
}
