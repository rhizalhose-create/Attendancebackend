// controller/login_controller.go
package controller

import (
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

	return c.JSON(fiber.Map{
		"message": "Login successful",
		"student_id": req.StudentID,
	})
}

// Optional: Add login by email endpoint
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

	return c.JSON(fiber.Map{
		"message": "Login successful",
		"email": req.Email,
	})
}