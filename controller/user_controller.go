package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"encoding/base64"
	"fmt"

	"github.com/gofiber/fiber/v2"
	"github.com/skip2/go-qrcode"
)

// GetMyQRCode returns the authenticated user's QR code data
func GetMyQRCode(c *fiber.Ctx) error {
	user, ok := c.Locals("user").(models.User)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	// If QR code doesn't exist, generate it
	if user.QRCodeData == "" {
		// Generate QR code
		qrContent := fmt.Sprintf("student:%s", user.StudentID)
		qrCodePNG, err := qrcode.Encode(qrContent, qrcode.Medium, 256)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to generate QR code"})
		}

		qrCodeBase64 := "data:image/png;base64," + base64.StdEncoding.EncodeToString(qrCodePNG)

		// Save the generated QR code to the database
		if err := connection.DB.Model(&user).Update("qr_code_data", qrCodeBase64).Error; err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to save QR code"})
		}

		user.QRCodeData = qrCodeBase64
	}

	return c.JSON(fiber.Map{"qr_code": user.QRCodeData})
}
