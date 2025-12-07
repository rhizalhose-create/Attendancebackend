// models/user_model.go

package models

import "time"


type User struct {
	ID              uint      `json:"-" gorm:"primaryKey;autoIncrement"`
	StudentID       string    `json:"student_id" gorm:"uniqueIndex;type:varchar(255);not null"`
	Email           string    `json:"email" gorm:"uniqueIndex;not null;type:varchar(255)"`
	Password        string    `json:"password" gorm:"not null;type:varchar(255)"`
	Username        string    `json:"username" gorm:"not null;type:varchar(255)"`
	Role            string    `json:"role" gorm:"not null;type:varchar(50);default:'student'"`
	IsVerified      bool      `json:"is_verified" gorm:"default:false"`
	CreatedAt       time.Time `json:"created_at" gorm:"autoCreateTime"`
	VerifiedAt      time.Time `json:"verified_at"`

	FirstName       string    `json:"first_name" gorm:"not null;type:varchar(100)"`
	LastName        string    `json:"last_name" gorm:"not null;type:varchar(100)"`
	MiddleName      string    `json:"middle_name,omitempty" gorm:"type:varchar(100)"`
	Course          string    `json:"course" gorm:"type:varchar(100)"`
	YearLevel       string    `json:"year_level" gorm:"type:varchar(50)"`
	Section         string    `json:"section,omitempty" gorm:"type:varchar(50)"`
	Department      string    `json:"department,omitempty" gorm:"type:varchar(100)"`
	College         string    `json:"college,omitempty" gorm:"type:varchar(100)"`
	ContactNumber   string    `json:"contact_number,omitempty" gorm:"type:varchar(20)"`
	Address         string    `json:"address,omitempty" gorm:"type:text"`

	QRCodeData string `json:"qr_code_data,omitempty" gorm:"type:text"`
	QRType          string    `json:"qr_type" gorm:"type:varchar(50);default:'attendance'"`
	QRGeneratedAt   time.Time `json:"qr_generated_at"`
}


type RegisterRequest struct {
	StudentID     string `json:"student_id,omitempty"` 
	Email         string `json:"email"`
	Password      string `json:"password"`
	Username      string `json:"username"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	MiddleName    string `json:"middle_name,omitempty"`
	Course        string `json:"course"`
	YearLevel     string `json:"year_level"`
	Section       string `json:"section,omitempty"`
	Department    string `json:"department,omitempty"`
	College       string `json:"college,omitempty"`
	ContactNumber string `json:"contact_number,omitempty"`
	Address       string `json:"address,omitempty"`
}


const (
	RoleSuperAdmin = "superadmin"
	RoleAdmin      = "admin"
	RoleFaculty    = "faculty"
	RoleStaff      = "staff"
	RoleStudent    = "student"
)