package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"attendance-system/services"
	"encoding/base64"
	"fmt"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/skip2/go-qrcode"
)

func VerifyEmail(c *fiber.Ctx) error {
	// Extract Bearer token from Authorization header
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return c.Status(401).JSON(fiber.Map{"error": "Authorization header is required"})
	}

	// Extract token from "Bearer <token>" format
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid authorization header format"})
	}

	token := parts[1]

	// Verify the token
	claims, err := services.VerifyEmailVerificationToken(token)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired token"})
	}

	// Parse request body - only code should be provided
	var req struct {
		Code string `json:"code"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if req.Code == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Code is required"})
	}

	// Verify the code matches the token claims
	if strings.TrimSpace(req.Code) != strings.TrimSpace(claims.Code) {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid verification code"})
	}

	// Find pending user by email
	var pending models.PendingUser
	if err := connection.DB.Where("email = ?", claims.Email).First(&pending).Error; err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Registration not found"})
	}

	// Check if code expired
	if time.Now().After(pending.ExpiresAt) {
		// Delete expired pending user
		connection.DB.Delete(&pending)
		return c.Status(400).JSON(fiber.Map{"error": "Verification code has expired. Please register again."})
	}

	// Generate QR code
	qrContent := fmt.Sprintf("student:%s", pending.StudentID)
	qrCodePNG, err := qrcode.Encode(qrContent, qrcode.Medium, 256)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate QR code"})
	}

	qrCodeBase64 := "data:image/png;base64," + base64.StdEncoding.EncodeToString(qrCodePNG)

	// Move to User table
	user := models.User{
		StudentID:     pending.StudentID,
		Email:         pending.Email,
		Password:      pending.Password,
		Username:      pending.Username,
		FirstName:     pending.FirstName,
		LastName:      pending.LastName,
		MiddleName:    pending.MiddleName,
		Course:        pending.Course,
		YearLevel:     pending.YearLevel,
		Section:       pending.Section,
		Department:    pending.Department,
		College:       pending.College,
		ContactNumber: pending.ContactNumber,
		Address:       pending.Address,

		QRCodeData: qrCodeBase64,
		IsVerified: true,
		VerifiedAt: time.Now(),
	}

	// Ensure ID is zero so DB assigns it (defensive against client-provided IDs)
	user.ID = 0
	if err := connection.DB.Omit("id").Create(&user).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create user account"})
	}

	// Delete from pending table
	connection.DB.Delete(&pending)

	return c.JSON(fiber.Map{
		"message": "Email verification successful",
		"status":  "success",
	})
}
