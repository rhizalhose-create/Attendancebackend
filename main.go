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
)

func main() {
	// ===============================
	// LOAD ENV
	// ===============================
	_ = godotenv.Load()

	// ===============================
	// LOGGER
	// ===============================
	if err := logging.InitLogger(); err != nil {
		fmt.Printf("Failed to initialize logger: %v\n", err)
	}

	// ===============================
	// DATABASE
	// ===============================
	connection.Connect()

	// ===============================
	// SEED SUPER ADMIN
	// ===============================
	seeder.SeedSuperAdmin()

	// ===============================
	// BACKGROUND JOB
	// ===============================
	go startEventStatusChecker()

	// ===============================
	// FIBER APP
	// ===============================
	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			msg := "An error occurred"
			if code < 500 {
				msg = err.Error()
			}

			return c.Status(code).JSON(fiber.Map{
				"error": msg,
			})
		},
		BodyLimit: 10 * 1024 * 1024, // 10MB
	})

	// ===============================
	// MIDDLEWARE
	// ===============================

	// Security headers
	app.Use(middleware.SecurityHeaders)

	// Rate limiting
	app.Use(middleware.RateLimit)

	// CORS (Flutter / APK SAFE)
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*", // change to domain in prod if needed
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS,PATCH",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		MaxAge:       300,
	}))

	// Request logger
	app.Use(middleware.RequestLogger())

	// ===============================
	// ROUTES
	// ===============================

	API.AuthRoutes(app)
	API.EventRoutes(app)
	API.AttendanceRoutes(app)

	// ===============================
	// PUBLIC HEALTH / PING
	// ===============================

	// Health check (NO AUTH)
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "attendance-backend",
			"time":    time.Now(),
		})
	})

	// Ping endpoint (USE THIS FOR APP INIT)
	app.Get("/ping", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"message": "pong",
			"time":    time.Now(),
		})
	})

	// Root info (NO AUTH)
	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"remote_ip":  c.IP(),
			"user_agent": c.Get("User-Agent"),
			"host":       c.Get("Host"),
		})
	})

	// ===============================
	// START SERVER
	// ===============================

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "3000"
	}

	fmt.Printf("\n🚀 Server running on port %s\n", port)
	fmt.Printf("🌍 Health: http://localhost:%s/health\n", port)
	fmt.Printf("📡 Ping:   http://localhost:%s/ping\n", port)

	defer logging.Logger.Sync()
	if err := app.Listen(":" + port); err != nil {
		panic(err)
	}
}

// ===============================
// BACKGROUND JOB
// ===============================
func startEventStatusChecker() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	// Run once at startup
	services.CheckAndUpdateCompletedEvents()

	for range ticker.C {
		services.CheckAndUpdateCompletedEvents()
	}
}
