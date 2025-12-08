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

	// Admin routes (require superadmin)
	adminRoutes := app.Group("/admin", middleware.RequireSuperAdmin)
	{
		adminRoutes.Get("/users", controller.GetAllUsers)
		adminRoutes.Post("/promote", controller.PromoteUser)
	}
}

// EventRoutes sets up event-related routes
func EventRoutes(app *fiber.App) {
	// Public routes (with basic auth)
	events := app.Group("/events", middleware.RequireAuth)
	{
		events.Get("/", controller.GetAllEvents)
		events.Get("/my-events", controller.GetMyEvents)
		events.Get("/:id", controller.GetEvent)
	}

	// Protected routes (faculty/admin only for creating)
	eventsProtected := app.Group("/events", middleware.RequireAuth, middleware.RequireFacultyOrAdmin)
	{
		eventsProtected.Post("/", controller.CreateEvent)
		eventsProtected.Put("/:id", controller.UpdateEvent)
		eventsProtected.Delete("/:id", controller.DeleteEvent)
	}
}

// AttendanceRoutes sets up attendance-related routes
func AttendanceRoutes(app *fiber.App) {
	// Student routes
	attendance := app.Group("/attendance", middleware.RequireAuth)
	{
		attendance.Post("/mark", controller.MarkAttendance)
		attendance.Get("/my-attendance", controller.GetMyAttendance)
		attendance.Get("/stats", controller.GetAttendanceStats)
	}

	// Event-specific attendance
	app.Get("/events/:event_id/attendance", middleware.RequireAuth, controller.GetAttendanceByEvent)

	// Admin/Faculty routes
	attendanceAdmin := app.Group("/attendance", middleware.RequireAuth, middleware.RequireFacultyOrAdmin)
	{
		attendanceAdmin.Put("/:id/status", controller.UpdateAttendanceStatus)
	}
}
