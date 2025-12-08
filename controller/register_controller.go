// controller/register_controller.go
package controller

import (
	"attendance-system/models"
	"attendance-system/services"
	"github.com/gofiber/fiber/v2"
)

func Register(c *fiber.Ctx) error {
	req := new(models.RegisterRequest)
	
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request format"})
	}

	// Validate required fields (StudentID is now optional)
	if req.Email == "" || req.Password == "" || req.Username == "" || req.FirstName == "" || req.LastName == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Email, password, username, first name, and last name are required"})
	}

	// Call service - NOW IT RETURNS 2 VALUES!
	generatedStudentID, err := services.RegisterService(*req)
	if err != nil {
		// Check what kind of error
		if err.Error() == "email and password are required" {
			return c.Status(400).JSON(fiber.Map{"error": "Email and password are required"})
		} else if err.Error() == "student_id already exists" {
			return c.Status(409).JSON(fiber.Map{"error": "Student ID already exists"})
		} else if err.Error() == "email already registered" {
			return c.Status(409).JSON(fiber.Map{"error": "Email already registered"})
		} else if err.Error() == "email already pending verification" {
			return c.Status(409).JSON(fiber.Map{"error": "Email already pending verification. Please check your email."})
		} else if err.Error() == "failed to generate unique student ID" {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to generate unique Student ID"})
		}
		return c.Status(500).JSON(fiber.Map{"error": "Registration failed: " + err.Error()})
	}

	return c.JSON(fiber.Map{
		"message":     "Registration successful. Please check your email for verification code and your Student ID.",
		"status":      "pending_verification",
		"student_id":  generatedStudentID, // Include the generated StudentID in response
	})
}