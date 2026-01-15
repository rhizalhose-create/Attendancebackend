package API

import (
	"attendance-system/controller"
	"attendance-system/middleware"

	"github.com/gofiber/fiber/v2"
)

/*
|--------------------------------------------------------------------------
| AUTH ROUTES
|--------------------------------------------------------------------------
| PUBLIC: register, login, verify, password reset
| PROTECTED: profile, QR, admin
*/
func AuthRoutes(app *fiber.App) {

	// ===============================
	// PUBLIC AUTH ROUTES
	// ===============================

	app.Post("/register", controller.Register)

	app.Post("/reg/verify", controller.VerifyEmail)
	app.Post("/verify", controller.VerifyEmail)

	app.Get("/registration-dropdowns", controller.GetRegistrationDropdowns)
	app.Post("/send-verification", controller.SendVerificationEmail)
	app.Post("/resend-verification", controller.ResendVerificationEmail)

	app.Post("/login", controller.Login)
	app.Post("/refresh-token", controller.RefreshToken)

	// Password reset (PUBLIC)
	app.Post("/forgot-password", controller.ForgotPassword)
	app.Post("/verify-reset-code", controller.VerifyResetCode)
	app.Post("/reset-password", controller.ResetPassword)
	app.Post("/resend-code", controller.ResendCode)

	// Backward compatibility
	fgtp := app.Group("/fgtp")
	{
		fgtp.Post("/forgot-password", controller.ForgotPassword)
		fgtp.Post("/verify-reset-code", controller.VerifyResetCode)
		fgtp.Post("/reset-password", controller.ResetPassword)
		fgtp.Post("/resend-code", controller.ResendCode)
	}

	// ===============================
	// PROTECTED AUTH ROUTES
	// ===============================

	protected := app.Group("/auth", middleware.RequireAuth)
	{
		protected.Get("/profile", controller.GetProfile)
		protected.Get("/qrcode", controller.GetMyQRCode)
	}

	// ===============================
	// ADMIN ROUTES (Admin + Superadmin)
	// ===============================

	admin := app.Group("/admin", middleware.RequireAuth, middleware.RequireAdmin)
	{
		admin.Get("/users", controller.GetAllUsers)
		admin.Get("/stats", controller.GetSystemStats)
		admin.Post("/promote", controller.PromoteUser)
	}

	// ===============================
	// SUPERADMIN ROUTES (Superadmin Only)
	// ===============================

	superadmin := app.Group("/superadmin", middleware.RequireAuth, middleware.RequireSuperAdmin)
	{
		superadmin.Get("/users", controller.GetAllUsersSuperadmin)
		superadmin.Get("/stats", controller.GetSystemStats)
	}
}

/*
|--------------------------------------------------------------------------
| EVENT ROUTES
|--------------------------------------------------------------------------
*/
func EventRoutes(app *fiber.App) {

	// ===============================
	// PUBLIC EVENT ROUTES
	// ===============================

	app.Get("/events/creation-dropdowns", controller.GetEventCreationDropdowns)

	// ===============================
	// AUTHENTICATED USERS
	// ===============================

	events := app.Group("/events", middleware.RequireAuth)
	{
		events.Get("/", controller.GetAllEvents)
		events.Get("/my-events", controller.GetMyEvents)
		events.Get("/:id", controller.GetEvent)
	}

	// ===============================
	// FACULTY / ADMIN
	// ===============================

	eventsAdmin := app.Group("/events",
		middleware.RequireAuth,
		middleware.RequireFacultyOrAdmin,
	)
	{
		eventsAdmin.Post("/", controller.CreateEvent)
		eventsAdmin.Put("/:id", controller.UpdateEvent)
		eventsAdmin.Delete("/:id", controller.DeleteEvent)
	}
}

/*
|--------------------------------------------------------------------------
| ATTENDANCE ROUTES
|--------------------------------------------------------------------------
*/
func AttendanceRoutes(app *fiber.App) {

	// ===============================
	// AUTHENTICATED USERS
	// ===============================

	attendance := app.Group("/attendance", middleware.RequireAuth)
	{
		attendance.Post("/mark", controller.MarkAttendance)
		attendance.Get("/my-attendance", controller.GetMyAttendance)
		attendance.Get("/stats", controller.GetAttendanceStats)
	}

	// ===============================
	// EVENT ATTENDANCE (ADMIN ONLY)
	// ===============================

	eventAttendance := app.Group(
		"/events/:event_id/attendance",
		middleware.RequireAuth,
		middleware.RequireAdmin,
	)
	{
		eventAttendance.Get("/", controller.GetAttendanceByEvent)
	}

	// ===============================
	// UPDATE STATUS (FACULTY / ADMIN)
	// ===============================

	attendanceAdmin := app.Group(
		"/attendance",
		middleware.RequireAuth,
		middleware.RequireFacultyOrAdmin,
	)
	{
		attendanceAdmin.Put("/:id/status", controller.UpdateAttendanceStatus)
	}
}
