// models/login_model.go

package models

type LoginRequest struct {
	StudentID      string `json:"student_id"`
	Password       string `json:"password"`
	RecaptchaToken string `json:"recaptcha_token,omitempty"`
}
