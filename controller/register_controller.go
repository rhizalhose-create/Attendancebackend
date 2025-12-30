package controller

import (
	"attendance-system/services"

	"github.com/gofiber/fiber/v2"
)

func Register(c *fiber.Ctx) error {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		Name     string `json:"name"`
		RecaptchaToken string `json:"recaptcha_token"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if req.Email == "" || req.Password == "" || req.Name == "" {
		return c.Status(400).JSON(fiber.Map{"error": "All fields are required"})
	}

	isValid, err := services.VerifyRecaptcha(req.RecaptchaToken)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Internal server error"})
	}
	if !isValid {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid reCAPTCHA"})
	}

	return c.JSON(fiber.Map{
		"message": "Register endpoint - implement logic",
		"status":  "success",
	})
}