// services/registration_service.go
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

func RegisterService(req models.RegisterRequest) (string, error) {
	fmt.Printf("RegisterService called with Email='%s'\n", req.Email)

	if err := validateRegistrationInput(req); err != nil {
		return "", err
	}

	studentID, err := generateOrValidateStudentID(req.StudentID)
	if err != nil {
		return "", err
	}

	if err := checkEmailDuplicates(req.Email); err != nil {
		return "", err
	}

	hashedPassword, err := hashPassword(req.Password)
	if err != nil {
		return "", err
	}

	verificationCode := generateVerificationCode()

	_, err = createPendingUser(req, studentID, hashedPassword, verificationCode)
	if err != nil {
		return "", err
	}

	if err := sendVerificationEmail(req.Email, studentID, verificationCode); err != nil {
		fmt.Printf("Failed to send email: %v\n", err)
	}

	fmt.Printf("Pending user created for: %s with StudentID: %s and code: %s\n", req.Email, studentID, verificationCode)
	return studentID, nil
}

func validateRegistrationInput(req models.RegisterRequest) error {
	if req.Email == "" || req.Password == "" {
		return errors.New("email and password are required")
	}
	return nil
}

func generateOrValidateStudentID(inputStudentID string) (string, error) {
	if inputStudentID == "" {
		return generateUniqueStudentID()
	}
	return validateExistingStudentID(inputStudentID)
}

func generateUniqueStudentID() (string, error) {
	currentTime := time.Now()
	datePart := currentTime.Format("060102")
	
	for i := 0; i < 10; i++ {
		randomPart := fmt.Sprintf("%04d", rand.Intn(10000))
		studentID := datePart + "-" + randomPart
		
		if isStudentIDUnique(studentID) {
			return studentID, nil
		}
	}
	
	return "", errors.New("failed to generate unique student ID")
}

func isStudentIDUnique(studentID string) bool {
	var existingUser models.User
	var existingPending models.PendingUser
	
	userResult := connection.DB.Where("student_id = ?", studentID).First(&existingUser)
	pendingResult := connection.DB.Where("student_id = ?", studentID).First(&existingPending)
	
	return userResult.Error != nil && pendingResult.Error != nil
}

func validateExistingStudentID(studentID string) (string, error) {
	if !isStudentIDUnique(studentID) {
		return "", errors.New("student_id already exists")
	}
	return studentID, nil
}

func checkEmailDuplicates(email string) error {
	var existingUser models.User
	var existingPending models.PendingUser
	
	if connection.DB.Where("email = ?", email).First(&existingUser).Error == nil {
		return errors.New("email already registered")
	}
	
	if connection.DB.Where("email = ?", email).First(&existingPending).Error == nil {
		return errors.New("email already pending verification")
	}
	
	return nil
}

func hashPassword(password string) (string, error) {
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	if err != nil {
		return "", err
	}
	return string(hashed), nil
}

func generateVerificationCode() string {
	rand.Seed(time.Now().UnixNano())
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

func createPendingUser(req models.RegisterRequest, studentID, hashedPassword, verificationCode string) (*models.PendingUser, error) {
	pending := &models.PendingUser{
		StudentID:        studentID,
		Email:            req.Email,
		Password:         hashedPassword,
		Username:         req.Username,
		FirstName:        req.FirstName,
		LastName:         req.LastName,
		MiddleName:       req.MiddleName,
		Course:           req.Course,
		YearLevel:        req.YearLevel,
		Section:          req.Section,
		Department:       req.Department,
		College:          req.College,
		ContactNumber:    req.ContactNumber,
		Address:          req.Address,
		VerificationCode: verificationCode,
		ExpiresAt:        time.Now().Add(30 * time.Minute),
	}

	if err := connection.DB.Create(pending).Error; err != nil {
		return nil, fmt.Errorf("failed to save pending user: %v", err)
	}
	
	return pending, nil
}

func sendVerificationEmail(email, studentID, verificationCode string) error {
	emailBody := fmt.Sprintf(`
		<h1>Email Verification</h1>
		<p>Thank you for registering!</p>
		<p><strong>Your Student ID:</strong> %s</p>
		<p><strong>Your verification code:</strong> <span style="font-size: 24px; font-weight: bold;">%s</span></p>
		<p>Enter this code on the verification page to complete your registration.</p>
		<p>This code will expire in 30 minutes.</p>
		<p><strong>Save your Student ID!</strong> You will need it to log in.</p>
		<hr>
		<p><small>If you did not register, please ignore this email.</small></p>
	`, studentID, verificationCode)

	return SendEmail(email, "Verification Code - Attendance System", emailBody)
}