// controller/verify_controller.go (bagong file)
package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"attendance-system/utils"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/skip2/go-qrcode"
)

func VerifyEmail(c *fiber.Ctx) error {
	type VerifyRequest struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}

	req := new(VerifyRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	// Sanitize inputs
	req.Email = utils.SanitizeEmail(req.Email)
	req.Code = utils.SanitizeString(req.Code)

	// Find pending user
	var pending models.PendingUser
	if err := connection.DB.Where("email = ? AND verification_code = ?", req.Email, req.Code).First(&pending).Error; err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid verification code or email"})
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

	// Move to User table
	user := models.User{
		StudentID:      pending.StudentID,
		Email:          pending.Email,
		Password:       pending.Password,
		Username:       pending.Username,
		FirstName:      pending.FirstName,
		LastName:       pending.LastName,
		MiddleName:     pending.MiddleName,
		Course:         pending.Course,
		YearLevel:      pending.YearLevel,
		Section:        pending.Section,
		Department:     pending.Department,
		College:        pending.College,
		ContactNumber:  pending.ContactNumber,
		Address:        pending.Address,
	
		QRCodeData:     "data:image/png;base64," + base64.StdEncoding.EncodeToString(qrCodePNG),
		IsVerified:     true,
		VerifiedAt:     time.Now(),
	}

	// Ensure ID is zero so DB assigns it (defensive against client-provided IDs)
	user.ID = 0
	if err := connection.DB.Omit("id").Create(&user).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create user account"})
	}

	// Delete from pending table
	connection.DB.Delete(&pending)

	return c.JSON(fiber.Map{
		"message":      "Email verified successfully!",
		"qr_code_data": user.QRCodeData,
		"user": fiber.Map{
			"student_id": user.StudentID,
			"email":      user.Email,
			"username":   user.Username,
			"first_name": user.FirstName,
			"last_name":  user.LastName,
		},
	})
}