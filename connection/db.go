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

	// Disable automatic foreign key constraint creation during AutoMigrate.
	// This avoids invalid FK creation (e.g., referencing non-unique columns)
	// and gives more control over DB schema in production.
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		DisableForeignKeyConstraintWhenMigrating: true,
	})
	if err != nil {
		log.Fatal("Failed to connect to DB:", err)
	}

	// Auto migrate ALL tables
	db.AutoMigrate(
		&models.User{},
		&models.PendingUser{},
		&models.PasswordReset{},
		&models.Event{},
		&models.Attendance{},
	)

	DB = db
	log.Println("Database connected!")
}
