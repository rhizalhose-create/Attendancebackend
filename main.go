package main

import (
	"attendance-system/API"
	"attendance-system/connection"
	"attendance-system/logging"
	"attendance-system/middleware"
	"attendance-system/seeder"
	"attendance-system/services"
	"fmt"
	"os"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/joho/godotenv"
	"go.uber.org/zap"
)

func main() {
	godotenv.Load()

	// Initialize modern logging system
	if err := logging.InitLogger(); err != nil {
		fmt.Printf("Failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	defer logging.Logger.Sync() // Flush logs on exit

	logging.Logger.Info("Starting Attendance System Backend")

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

	// Request logging with IP
	app.Use(middleware.RequestLogger())

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

	// Debug: echo client info (IP + some headers)
	app.Get("/debug/echo", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"remote_ip":       c.IP(),
			"user_agent":      c.Get("User-Agent"),
			"host":            c.Get("Host"),
			"x_forwarded_for": c.Get("X-Forwarded-For"),
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

	// Log server info
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "3000"
	}

	logging.Logger.Info("Server starting",
		zap.String("port", port),
		zap.String("host", "0.0.0.0"),
	)
	logging.Logger.Info("Test endpoints available",
		zap.String("test", fmt.Sprintf("http://localhost:%s/test", port)),
		zap.String("health", fmt.Sprintf("http://localhost:%s/health", port)),
		zap.String("login", fmt.Sprintf("http://localhost:%s/login (POST)", port)),
		zap.String("register", fmt.Sprintf("http://localhost:%s/register (POST)", port)),
	)
	logging.Logger.Info("Admin endpoints (require Bearer SUPERADMIN token)",
		zap.String("users", fmt.Sprintf("GET http://localhost:%s/admin/users", port)),
		zap.String("promote", fmt.Sprintf("POST http://localhost:%s/admin/promote", port)),
	)
	logging.Logger.Info("Default SuperAdmin credentials",
		zap.String("student_id", "SUPERADMIN"),
		zap.String("password", "superadmin123"),
	)

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
