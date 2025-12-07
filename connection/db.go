// connection/db.go
package connection

import (
	"log"
	"os"

	"attendance-system/models"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB 

func Connect() {
	godotenv.Load()

	dsn := "host=" + os.Getenv("DB_HOST") +
		" user=" + os.Getenv("DB_USER") +
		" password=" + os.Getenv("DB_PASSWORD") +
		" dbname=" + os.Getenv("DB_NAME") +
		" port=" + os.Getenv("DB_PORT") +
		" sslmode=disable"

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}

	// Auto migrate ALL tables
	db.AutoMigrate(
		&models.User{}, 
		&models.PendingUser{},
		&models.PasswordReset{}, // Add this line
	)

	DB = db
	log.Println("Database connected!")
}