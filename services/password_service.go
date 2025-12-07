// services/password_service.go
package services

import (
	"attendance-system/connection"
	"attendance-system/models"
	"errors"
	"fmt"
	"math/rand"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// Constants
const (
	emailQuery = "email = ?"
	codeQuery  = "email = ? AND code = ? AND used = ? AND expires_at > ?"
)

func ForgotPassword(email string) (string, error) {
	// Check if email exists in users table
	var user models.User
	if err := connection.DB.Where(emailQuery, email).First(&user).Error; err != nil {
		// For security, don't reveal if email exists
		fmt.Printf("Password reset requested for: %s\n", email)
		return "", nil
	}

	// Generate 6-digit code (same as verification)
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	// Save to password_resets table
	reset := models.PasswordReset{
		Email:     email,
		Code:      code,
		ExpiresAt: time.Now().Add(15 * time.Minute), // 15 minutes only
		Used:      false,
	}

	if err := connection.DB.Create(&reset).Error; err != nil {
		return "", fmt.Errorf("failed to create reset record: %v", err)
	}

	// Send email with code
	emailBody := fmt.Sprintf(`
		<h1>Password Reset Code</h1>
		<p>You requested to reset your password.</p>
		<p>Your password reset code is: <strong style="font-size: 24px;">%s</strong></p>
		<p>Enter this code on the password reset page.</p>
		<p>This code will expire in 15 minutes.</p>
		<p>If you didn't request this, please ignore this email.</p>
	`, code)

	if err := SendEmail(email, "Password Reset Code - Attendance System", emailBody); err != nil {
		fmt.Printf("Failed to send reset email: %v\n", err)
	}

	fmt.Printf("Reset code sent to: %s, code: %s\n", email, code)
	return code, nil
}

func VerifyResetCode(email, code string) error {
	var reset models.PasswordReset
	if err := connection.DB.Where(codeQuery, email, code, false, time.Now()).First(&reset).Error; err != nil {
		return errors.New("invalid or expired reset code")
	}
	return nil
}

func ResetPasswordWithCode(email, code, newPassword string) error {
	// Verify code first
	var reset models.PasswordReset
	if err := connection.DB.Where(codeQuery, email, code, false, time.Now()).First(&reset).Error; err != nil {
		return errors.New("invalid or expired reset code")
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), 12)
	if err != nil {
		return fmt.Errorf("failed to hash password: %v", err)
	}

	// Find user
	var user models.User
	if err := connection.DB.Where(emailQuery, email).First(&user).Error; err != nil {
		return errors.New("user not found")
	}

	// Update password
	if err := connection.DB.Model(&user).Update("password", string(hashedPassword)).Error; err != nil {
		return fmt.Errorf("failed to update password: %v", err)
	}

	// Mark code as used
	if err := connection.DB.Model(&reset).Update("used", true).Error; err != nil {
		fmt.Printf("Failed to mark code as used: %v\n", err)
	}

	// Send confirmation email
	emailBody := `
		<h1>Password Changed</h1>
		<p>Your password has been successfully reset.</p>
		<p>You can now login with your new password.</p>
		<p>If you didn't make this change, contact support immediately.</p>`

	if err := SendEmail(email, "Password Changed - Attendance System", emailBody); err != nil {
		fmt.Printf("Failed to send confirmation: %v\n", err)
	}

	fmt.Printf("Password reset for: %s\n", email)
	return nil
}

// Resend reset code
func ResendResetCode(email string) (string, error) {
	// Delete any existing unused codes for this email
	connection.DB.Where("email = ? AND used = ?", email, false).Delete(&models.PasswordReset{})
	
	// Generate and send new code
	return ForgotPassword(email)
}