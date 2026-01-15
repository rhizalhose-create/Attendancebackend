package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"attendance-system/services"
	"encoding/base64"
	"fmt"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/skip2/go-qrcode"
)

func VerifyEmail(c *fiber.Ctx) error {
	// Accept multiple verification methods for convenience:
	// 1) Authorization: Bearer <token> (preferred)
	// 2) JSON body: { "token": "...", "code": "..." }
	// 3) Fallback JSON body: { "email": "...", "code": "..." } (less secure)

	// Parse request data (accept code, token or email)
	var req struct {
		Code  string `json:"code"`
		Token string `json:"token,omitempty"`
		Email string `json:"email,omitempty"`
	}

	// Support GET with query parameters for easier testing (e.g. Postman GET)
	if c.Method() == "GET" {
		req.Code = c.Query("code")
		req.Token = c.Query("token")
		req.Email = c.Query("email")
		// If no query params provided, try parsing JSON body for clients that send body with GET (Postman)
		if req.Code == "" && req.Token == "" && req.Email == "" {
			if err := c.BodyParser(&req); err != nil {
				return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
			}
		}
	} else {
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}
	}

	if req.Code == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Code is required"})
	}

	// Trim code for consistent handling
	req.Code = strings.TrimSpace(req.Code)
	fmt.Printf("📧 Verify Email: Code=%s, Email=%s, HasToken=%v\n", req.Code, req.Email, req.Token != "")

	// Determine token: prefer Authorization header, then body token
	authHeader := c.Get("Authorization")
	var token string
	if authHeader != "" {
		parts := strings.Split(authHeader, " ")
		if len(parts) == 2 && parts[0] == "Bearer" {
			token = parts[1]
		}
	}
	if token == "" && req.Token != "" {
		token = req.Token
	}

	var pending models.PendingUser
	verifiedByToken := false
	var claims *models.EmailVerificationTokenClaims

	if token != "" {
		// Try to verify token. If token is invalid/expired we will fall back
		// to email+code verification when the client provided `email`.
		tokenClaims, err := services.VerifyEmailVerificationToken(token)
		if err == nil {
			claims = tokenClaims
			// Verify the code matches the token claims (with trimming)
			if strings.TrimSpace(req.Code) != strings.TrimSpace(claims.Code) {
				fmt.Printf("❌ Code mismatch: expected=%s, got=%s\n", strings.TrimSpace(claims.Code), strings.TrimSpace(req.Code))
				return c.Status(400).JSON(fiber.Map{"error": "Invalid verification code"})
			}

			// Find pending user by email from claims
			if err := connection.DB.Where("email = ?", claims.Email).First(&pending).Error; err != nil {
				fmt.Printf("❌ Pending user not found: %s\n", claims.Email)
				return c.Status(400).JSON(fiber.Map{"error": "Registration not found"})
			}

			// Check if code expired (compare in UTC)
			if time.Now().UTC().After(pending.ExpiresAt.UTC()) {
				connection.DB.Delete(&pending)
				fmt.Printf("❌ Code expired for: %s\n", claims.Email)
				return c.Status(400).JSON(fiber.Map{"error": "Verification code has expired. Please register again."})
			}

			fmt.Printf("✅ Email verified by token: %s\n", claims.Email)
			verifiedByToken = true
		} else {
			// Token invalid/expired. If no email provided, return 401; otherwise fall through to email+code fallback.
			fmt.Printf("⚠️ Token verification failed: %v. Trying email+code fallback...\n", err)
			if req.Email == "" {
				return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired token"})
			}
		}
	}

	if !verifiedByToken {
		// No valid token — verify by email + code (fallback)
		if req.Email == "" {
			return c.Status(401).JSON(fiber.Map{"error": "Authorization header or token is required (or provide email+code)"})
		}

		req.Email = strings.TrimSpace(req.Email)
		fmt.Printf("📧 Verifying by email+code: %s | code: %s\n", req.Email, req.Code)

		if err := connection.DB.Where("email = ?", req.Email).First(&pending).Error; err != nil {
			fmt.Printf("❌ Registration not found: %s\n", req.Email)
			return c.Status(400).JSON(fiber.Map{"error": "Registration not found"})
		}

		// Validate code and expiry (compare in UTC) - with trimming
		pendingCode := strings.TrimSpace(pending.VerificationCode)
		reqCode := strings.TrimSpace(req.Code)
		if reqCode != pendingCode {
			fmt.Printf("❌ Code mismatch for %s: expected=%s, got=%s\n", req.Email, pendingCode, reqCode)
			return c.Status(400).JSON(fiber.Map{"error": "Invalid verification code"})
		}
		if time.Now().UTC().After(pending.ExpiresAt.UTC()) {
			connection.DB.Delete(&pending)
			fmt.Printf("❌ Code expired for: %s\n", req.Email)
			return c.Status(400).JSON(fiber.Map{"error": "Verification code has expired. Please register again."})
		}

		fmt.Printf("✅ Email verified by email+code: %s\n", req.Email)
	}

	// Generate QR code
	qrContent := fmt.Sprintf("student:%s", pending.StudentID)
	qrCodePNG, err := qrcode.Encode(qrContent, qrcode.Medium, 256)
	if err != nil {
		fmt.Printf("❌ QR code generation failed: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate QR code"})
	}

	qrCodeBase64 := "data:image/png;base64," + base64.StdEncoding.EncodeToString(qrCodePNG)

	// Move to User table
	user := models.User{
		StudentID:     pending.StudentID,
		Email:         pending.Email,
		Password:      pending.Password,
		Username:      pending.Username,
		FirstName:     pending.FirstName,
		LastName:      pending.LastName,
		MiddleName:    pending.MiddleName,
		Course:        pending.Course,
		YearLevel:     pending.YearLevel,
		Section:       pending.Section,
		Department:    pending.Department,
		College:       pending.College,
		ContactNumber: pending.ContactNumber,
		Address:       pending.Address,

		QRCodeData: qrCodeBase64,
		IsVerified: true,
		VerifiedAt: time.Now(),
	}

	// Ensure ID is zero so DB assigns it (defensive against client-provided IDs)
	user.ID = 0
	if err := connection.DB.Omit("id").Create(&user).Error; err != nil {
		fmt.Printf("❌ User creation failed: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create user account"})
	}

	// Delete from pending table
	connection.DB.Delete(&pending)

	fmt.Printf("✅ User successfully created and verified: %s (%s)\n", user.Email, user.StudentID)

	return c.JSON(fiber.Map{
		"message": "Email verification successful",
		"status":  "success",
	})
}

// SendVerificationEmail sends the existing verification code for pending registration (without generating a new one)
func SendVerificationEmail(c *fiber.Ctx) error {
	type Request struct {
		Email string `json:"email"`
	}

	req := new(Request)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if req.Email == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Email is required"})
	}

	// Get the pending user with the EXISTING code (don't generate new one)
	var pending models.PendingUser
	if err := connection.DB.Where("email = ?", req.Email).First(&pending).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Registration not found", "status": "not_found"})
	}

	// Check if already verified
	var user models.User
	if userResult := connection.DB.Where("email = ?", req.Email).First(&user); userResult.Error == nil {
		return c.Status(409).JSON(fiber.Map{"error": "User is already verified. Please login to your account", "status": "already_verified"})
	}

	// Resend the EXISTING email with the EXISTING code (no new code generation)
	if err := services.SendExistingVerificationEmail(pending.Email, pending.StudentID, pending.VerificationCode); err != nil {
		fmt.Printf("❌ Failed to send verification email to %s: %v\n", req.Email, err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to send verification email", "status": "email_error"})
	}

	fmt.Printf("✅ Verification email sent (no new code) to %s with existing code\n", req.Email)

	// Generate token with the EXISTING code
	token, err := services.GenerateEmailVerificationToken(pending.Email, pending.VerificationCode)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate token"})
	}

	return c.JSON(fiber.Map{
		"message":    "Verification code sent successfully. Please check your email.",
		"student_id": pending.StudentID,
		"token":      token,
		"status":     "success",
	})
}

// ResendVerificationEmail resends verification email for registration
func ResendVerificationEmail(c *fiber.Ctx) error {
	type Request struct {
		Email string `json:"email"`
	}

	req := new(Request)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
	}

	if req.Email == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Email is required"})
	}

	studentID, token, err := services.ResendVerificationEmail(req.Email)
	if err != nil {
		errMsg := err.Error()

		// Return appropriate status based on error type
		switch {
		case strings.Contains(errMsg, "already verified"):
			// User already verified - return 409 Conflict
			return c.Status(409).JSON(fiber.Map{"error": errMsg, "status": "already_verified"})
		case strings.Contains(errMsg, "not found"):
			// Email not registered - return 404
			return c.Status(404).JSON(fiber.Map{"error": errMsg, "status": "not_found"})
		case strings.Contains(errMsg, "failed to send"):
			// Email sending failed - return 500
			return c.Status(500).JSON(fiber.Map{"error": errMsg, "status": "email_error"})
		default:
			// Generic error - return 400
			return c.Status(400).JSON(fiber.Map{"error": errMsg})
		}
	}

	return c.JSON(fiber.Map{
		"message":    "Verification code resent successfully. Please check your email.",
		"student_id": studentID,
		"token":      token,
		"status":     "success",
	})
}
