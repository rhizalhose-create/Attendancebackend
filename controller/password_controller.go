package controller

import (
	"attendance-system/models"
	"attendance-system/services"
	"attendance-system/utils"
	"fmt"
	"strings"

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

func ForgotPassword(c *fiber.Ctx) error {
	req := new(models.ResetPasswordRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": ErrInvalidRequest})
	}

	if req.Email == "" {
		return c.Status(400).JSON(fiber.Map{"error": ErrEmailRequired})
	}

	// Always return success (security), but get token if email exists
	_, token, err := services.ForgotPassword(req.Email)
	if err != nil {
		// Still return success message for security, but with empty token
		return c.JSON(fiber.Map{
			"message": SuccessResetCodeSent,
			"status":  "success",
			"token":   "",
		})
	}

	return c.JSON(fiber.Map{
		"message": SuccessResetCodeSent,
		"status":  "success",
		"token":   token,
	})
}

// VerifyResetCode verifies the reset code using multiple methods
// Methods:
// 1) Authorization: Bearer <token> + { "code": "123456" } (preferred)
// 2) Request body: { "token": "...", "code": "123456" }
// 3) Fallback: { "email": "...", "code": "123456" } (simplest)
// Response: { "message": "Code is valid", "status": "success", "token": "new_token_for_reset_password" }
func VerifyResetCode(c *fiber.Ctx) error {
	type VerifyRequest struct {
		Code  string `json:"code"`
		Email string `json:"email,omitempty"`
		Token string `json:"token,omitempty"`
	}

	req := new(VerifyRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": ErrInvalidRequest})
	}

	if req.Code == "" {
		return c.Status(400).JSON(fiber.Map{"error": ErrCodeRequired})
	}

	// Trim code for consistent handling
	req.Code = strings.TrimSpace(req.Code)
	fmt.Printf("🔑 Verify Reset Code: Code=%s, Email=%s, HasToken=%v\n", req.Code, req.Email, req.Token != "")

	var claims *models.PasswordResetTokenClaims
	var token string

	// Try to get token from Authorization header first
	auth := c.Get("Authorization")
	if auth != "" {
		const bearerPrefix = "Bearer "
		if len(auth) >= len(bearerPrefix) && auth[:len(bearerPrefix)] == bearerPrefix {
			token = auth[len(bearerPrefix):]
			fmt.Printf("📌 Found token in Authorization header\n")
		}
	}

	// If no token in header, try request body
	if token == "" && req.Token != "" {
		token = req.Token
		fmt.Printf("📌 Found token in request body\n")
	}

	// Try to verify token if we have one
	if token != "" {
		var err error
		claims, err = services.VerifyPasswordResetToken(token)
		if err != nil {
			fmt.Printf("⚠️ Token verification failed: %v. Trying email+code fallback...\n", err)
			// If token fails and no email provided, return error
			if req.Email == "" {
				return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired token. Use email+code instead."})
			}
			// Otherwise fall through to email+code verification
		} else {
			fmt.Printf("✅ Token verified successfully\n")
		}
	}

	var email string

	if claims != nil {
		// Token is valid - use email from claims
		email = claims.Email
		fmt.Printf("📧 Using email from token: %s\n", email)

		// Verify the code in database with the email from token
		err := services.VerifyResetCodeDB(email, req.Code)
		if err != nil {
			fmt.Printf("❌ Code verification failed: %v\n", err)
			return c.Status(400).JSON(fiber.Map{"error": "Invalid or expired code"})
		}
	} else {
		// No valid token — verify by email + code (simplest method)
		if req.Email == "" {
			return c.Status(400).JSON(fiber.Map{
				"error": "Email is required. Send: {\"email\": \"...\", \"code\": \"123456\"} or use Authorization header with token",
			})
		}

		email = strings.TrimSpace(req.Email)
		fmt.Printf("📧 Verifying by email+code: %s | code: %s\n", email, req.Code)

		// Verify the code in database
		err := services.VerifyResetCodeDB(email, req.Code)
		if err != nil {
			fmt.Printf("❌ Code verification failed: %v\n", err)
			return c.Status(400).JSON(fiber.Map{"error": "Invalid or expired code"})
		}
	}

	fmt.Printf("✅ Code verified successfully for: %s\n", email)

	// Code is valid - generate a new token for /reset-password endpoint
	newToken, err := services.GeneratePasswordResetToken(email, req.Code)
	if err != nil {
		fmt.Printf("❌ Failed to generate token: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate token"})
	}

	return c.JSON(fiber.Map{
		"message": SuccessCodeValid,
		"status":  "success",
		"email":   email,
		"token":   newToken,
	})
}

func ResetPassword(c *fiber.Ctx) error {
	type ResetPasswordRequest struct {
		NewPassword        string `json:"new_password"`
		ConfirmNewPassword string `json:"confirm_new_password"`
	}

	req := new(ResetPasswordRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": ErrInvalidRequest})
	}

	if req.NewPassword == "" || req.ConfirmNewPassword == "" {
		return c.Status(400).JSON(fiber.Map{"error": ErrAllFieldsRequired})
	}

	// Validate passwords match
	if req.NewPassword != req.ConfirmNewPassword {
		return c.Status(400).JSON(fiber.Map{"error": "Passwords do not match"})
	}

	if valid, msg := utils.ValidatePassword(req.NewPassword); !valid {
		return c.Status(400).JSON(fiber.Map{"error": msg})
	}

	// Get bearer token from Authorization header
	auth := c.Get("Authorization")
	if auth == "" {
		return c.Status(401).JSON(fiber.Map{"error": "Authorization header required"})
	}

	// Extract token from "Bearer <token>"
	const bearerPrefix = "Bearer "
	if len(auth) < len(bearerPrefix) || auth[:len(bearerPrefix)] != bearerPrefix {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid authorization format. Use: Bearer <token>"})
	}

	token := auth[len(bearerPrefix):]

	// Verify the JWT token
	claims, err := services.VerifyPasswordResetToken(token)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired token"})
	}

	// Reset password using email from token (code already verified in /verify-reset-code)
	err = services.ResetPasswordWithCode(claims.Email, claims.Code, req.NewPassword)
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

	_, token, err := services.ResendResetCode(req.Email)
	if err != nil {
	}

	return c.JSON(fiber.Map{
		"message": SuccessNewCodeSent,
		"status":  "success",
		"token":   token,
	})
}
