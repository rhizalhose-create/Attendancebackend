
//seeder/seed.go

package seeder

import (
    "attendance-system/connection"
    "attendance-system/models"
    "golang.org/x/crypto/bcrypt"
    "log"
    "time"
)

func SeedSuperAdmin() {
    db := connection.DB

    var count int64
    db.Model(&models.User{}).Where("role = ?", "superadmin").Count(&count)

    if count > 0 {
        log.Println("SuperAdmin already exists. Skipping seed.")
        return
    }

    hashedPassword, err := bcrypt.GenerateFromPassword([]byte("superadmin123"), bcrypt.DefaultCost)
    if err != nil {
        log.Println("Failed to hash password for superadmin:", err)
        return
    }

    superadmin := models.User{
        StudentID:    "SUPERADMIN",
        Username:     "superadmin",
        Email:        "superadmin@example.com",
        Password:     string(hashedPassword),
        Role:         "superadmin",
        IsVerified:   true,
        FirstName:    "Super",
        LastName:     "Admin",
        CreatedAt:    time.Now(),
        VerifiedAt:   time.Now(),
    }

    if err := db.Create(&superadmin).Error; err != nil {
        log.Println("Failed to create SuperAdmin:", err)
        return
    }

    log.Println("Default SuperAdmin created successfully!")
}
