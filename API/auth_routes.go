package API

import (
	"attendance-system/controller"
	"attendance-system/middleware"

	"github.com/gofiber/fiber/v2"
)

func AuthRoutes(app *fiber.App) {
	// PUBLIC routes - NO authentication required
	// Registration routes
	app.Post("/register", controller.Register)
	app.Post("/reg/verify", controller.VerifyEmail)

	// Login routes
	app.Post("/login", controller.Login)
	app.Post("/refresh-token", controller.RefreshToken)

	// Forgot-to-Password (FGTP) routes
	fgtp := app.Group("/fgtp")
	{
		fgtp.Post("/forgot-password", controller.ForgotPassword)
		fgtp.Post("/verify-reset-code", controller.VerifyResetCode)
		fgtp.Post("/reset-password", controller.ResetPassword)
		fgtp.Post("/resend-code", controller.ResendCode)
	}

	// Protected routes (require authentication)
	protected := app.Group("", middleware.RequireAuth)
	{
		protected.Get("/profile", controller.GetProfile)
	}

	adminRoutes := app.Group("/admin", middleware.RequireAuth, middleware.RequireSuperAdmin)
	{
		adminRoutes.Get("/users", controller.GetAllUsers)
		adminRoutes.Post("/promote", controller.PromoteUser)
	}
}

func EventRoutes(app *fiber.App) {
	events := app.Group("/events", middleware.RequireAuth)
	{
		events.Get("/", controller.GetAllEvents)
		events.Get("/my-events", controller.GetMyEvents)
		events.Get("/:id", controller.GetEvent)
	}

	eventsProtected := app.Group("/events", middleware.RequireAuth, middleware.RequireFacultyOrAdmin)
	{
		eventsProtected.Post("/", controller.CreateEvent)
		eventsProtected.Put("/:id", controller.UpdateEvent)
		eventsProtected.Delete("/:id", controller.DeleteEvent)
	}
}

func AttendanceRoutes(app *fiber.App) {
	attendance := app.Group("/attendance", middleware.RequireAuth)
	{
		attendance.Post("/mark", controller.MarkAttendance)
		attendance.Get("/my-attendance", controller.GetMyAttendance)
		attendance.Get("/stats", controller.GetAttendanceStats)
	}

	app.Get("/events/:event_id/attendance", middleware.RequireAuth, controller.GetAttendanceByEvent)

	attendanceAdmin := app.Group("/attendance", middleware.RequireAuth, middleware.RequireFacultyOrAdmin)
	{
		attendanceAdmin.Put("/:id/status", controller.UpdateAttendanceStatus)
	}
}
