// services/login_service.go
package services

import (
	"attendance-system/connection"
	"attendance-system/models"
	"errors"
	"golang.org/x/crypto/bcrypt"
)

func LoginService(req models.LoginRequest) error {
	var user models.User

	// Find user by StudentID
	err := connection.DB.Where("student_id = ?", req.StudentID).First(&user).Error
	if err != nil {
		return errors.New("user not found")
	}

	// Check if user is verified
	if !user.IsVerified {
		return errors.New("account not verified")
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password))
	if err != nil {
		return errors.New("wrong password")
	}

	return nil
}

// Optional: Add login by email service
func LoginByEmailService(email, password string) error {
	var user models.User

	// Find user by Email
	err := connection.DB.Where("email = ?", email).First(&user).Error
	if err != nil {
		return errors.New("user not found")
	}

	// Check if user is verified
	if !user.IsVerified {
		return errors.New("account not verified")
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return errors.New("wrong password")
	}

	return nil
}