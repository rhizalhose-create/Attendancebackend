package controller

import (
	"github.com/gofiber/fiber/v2"
)

func GetAllUsers(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Get all users endpoint - implement logic",
		"status":  "success",
	})
}

func PromoteUser(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Promote user endpoint - implement logic",
		"status":  "success",
	})
}