package API

import (
	"attendance-system/controller"
	"attendance-system/middleware"
	"github.com/gofiber/fiber/v2"
)

func AuthRoutes(app *fiber.App) {
	// Public routes
	app.Post("/register", controller.Register)
	app.Post("/login", controller.Login)
	app.Post("/login/email", controller.LoginByEmail)
	app.Post("/verify", controller.VerifyEmail)

	// Password reset routes
	app.Post("/forgot-password", controller.ForgotPassword)
	app.Post("/reset-password", controller.ResetPassword)
	app.Post("/resend-reset-code", controller.ResendCode)

	// Get current user (requires auth) - NEW ENDPOINT
	app.Get("/users/me", middleware.RequireAuth, controller.GetCurrentUser)

	// Admin routes (require superadmin)
	adminRoutes := app.Group("/admin", middleware.RequireSuperAdmin)
	{
		adminRoutes.Get("/users", controller.GetAllUsers)
		adminRoutes.Get("/users/:student_id", controller.GetUserByStudentID)  // ← NEW ENDPOINT
		adminRoutes.Post("/promote", controller.PromoteUser)
	}
}

