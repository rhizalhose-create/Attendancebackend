package API

import (
	"attendance-system/controller"
	"attendance-system/middleware"

	"github.com/gofiber/fiber/v2"
)

func AuthRoutes(app *fiber.App) {
	app.Post("/register", controller.Register)
	app.Post("/login", controller.Login)
	app.Post("/verify", controller.VerifyEmail)
	app.Post("/refresh-token", controller.RefreshToken)

	// Protected routes (require authentication)
	protected := app.Group("", middleware.RequireAuth)
	{
		protected.Get("/profile", controller.GetProfile)
	}

	app.Post("/forgot-password", controller.ForgotPassword)
	app.Post("/reset-password", controller.ResetPassword)
	app.Post("/resend-reset-code", controller.ResendCode)

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