package main

import (
	"attendance-system/API"
	"attendance-system/connection"
	"attendance-system/seeder"
	"fmt"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	connection.Connect()
	seeder.SeedSuperAdmin()

	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins: "*", 
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowCredentials: false,
	}))

	app.Get("/test", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Go backend is working!",
		})
	})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "healthy",
			"service": "attendance-system",
		})
	})

	API.AuthRoutes(app)

	// Print server info
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "3000"
	}

	fmt.Printf(" Server starting on port %s...\n", port)
	fmt.Printf(" Test endpoints:\n")
	fmt.Printf("   http://localhost:%s/test\n", port)
	fmt.Printf("   http://localhost:%s/health\n", port)
	fmt.Printf("   http://localhost:%s/login (POST)\n", port)
	fmt.Printf("   http://localhost:%s/register (POST)\n", port)
	fmt.Printf("\n Admin endpoints (requires Bearer SUPERADMIN token):\n")
	fmt.Printf("   GET  http://localhost:%s/admin/users\n", port)
	fmt.Printf("   POST http://localhost:%s/admin/promote\n", port)
	fmt.Printf("\n Default SuperAdmin:\n")
	fmt.Printf("   StudentID: SUPERADMIN\n")
	fmt.Printf("   Password: superadmin123\n")

	app.Listen(":" + port)
}