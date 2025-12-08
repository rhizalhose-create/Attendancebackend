// controller/login_controller.go
package controller

import (
	"attendance-system/models"
	"attendance-system/services"
	"attendance-system/utils"
	"strings"

	"github.com/gofiber/fiber/v2"
)

const failedFetchUserProfile = "failed to fetch user profile"

func Login(c *fiber.Ctx) error {
	req := new(models.LoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	// Verify reCAPTCHA token if configured
	if ok, err := services.VerifyRecaptcha(req.RecaptchaToken, c.IP(), "login"); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": utils.ErrRecaptchaVerificationFailed})
	} else if !ok {
		return c.Status(400).JSON(fiber.Map{"error": utils.ErrRecaptchaVerificationFailed})
	}

	if err := services.LoginService(*req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
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
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}
	// Verify reCAPTCHA token if configured
	if ok, err := services.VerifyRecaptcha(req.RecaptchaToken, c.IP(), "login"); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": utils.ErrRecaptchaVerificationFailed})
	} else if !ok {
		return c.Status(400).JSON(fiber.Map{"error": utils.ErrRecaptchaVerificationFailed})
	}

	if err := services.LoginByEmailService(req.Email, req.Password); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	var user models.User
	if err := services.GetUserByEmail(req.Email, &user); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": failedFetchUserProfile})
	}

	return c.JSON(fiber.Map{
		"message":    "Login successful",
		"email":      req.Email,
		"student_id": user.StudentID,
		"role":       user.Role,
		"first_name": user.FirstName,
		"last_name":  user.LastName,
	})
}
