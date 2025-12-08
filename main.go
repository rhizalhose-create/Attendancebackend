package main

import (
	"attendance-system/API"
	"attendance-system/connection"
	"attendance-system/middleware"
	"attendance-system/seeder"
	"attendance-system/services"
	"fmt"
	"os"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	connection.Connect()
	seeder.SeedSuperAdmin()

	// Start background job to check completed events and revert QR codes
	go startEventStatusChecker()

	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			// Don't expose internal error details in production
			errorMsg := "An error occurred"
			if code < 500 {
				errorMsg = err.Error()
			}
			return c.Status(code).JSON(fiber.Map{
				"error": errorMsg,
			})
		},
		BodyLimit: 10 * 1024 * 1024, // 10MB limit for request body
	})

	// Security headers
	app.Use(middleware.SecurityHeaders)

	// Rate limiting
	app.Use(middleware.RateLimit)

	// CORS Configuration - Security: Restrict origins in production
	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowedOrigins == "" {
		allowedOrigins = "*" // Default for development, change in production
	}

	// Security: Fiber's CORS middleware disallows AllowCredentials=true with wildcard origins.
	// If a wildcard origin is used (development), disable credentials to avoid panic.
	allowCredentials := true
	if allowedOrigins == "*" {
		allowCredentials = false
	}

	app.Use(cors.New(cors.Config{
		AllowOrigins:     allowedOrigins,
		AllowMethods:     "GET,POST,PUT,DELETE,OPTIONS,PATCH",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization, X-Requested-With",
		AllowCredentials: allowCredentials,
		ExposeHeaders:    "Content-Length",
		MaxAge:           3600, // 1 hour
	}))

	app.Get("/test", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Go backend is working!",
		})
	})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"service": "attendance-system",
		})
	})

	API.AuthRoutes(app)
	API.EventRoutes(app)
	API.AttendanceRoutes(app)

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

// startEventStatusChecker runs a background job to check and update completed events
func startEventStatusChecker() {
	// Check every 5 minutes
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	// Run immediately on startup
	services.CheckAndUpdateCompletedEvents()

	for range ticker.C {
		services.CheckAndUpdateCompletedEvents()
	}
}
