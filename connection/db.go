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


	if !db.Migrator().HasColumn(&models.Event{}, "tagged_courses") {
		// Try to add column using GORM migrator (field name)
		if err := db.Migrator().AddColumn(&models.Event{}, "TaggedCoursesCSV"); err != nil {
			log.Printf("Failed to add column tagged_courses: %v", err)
			// Fallback: attempt a safe raw ALTER TABLE (IF NOT EXISTS)
			if execErr := db.Exec("ALTER TABLE events ADD COLUMN IF NOT EXISTS tagged_courses text").Error; execErr != nil {
				log.Printf("Fallback ALTER TABLE failed: %v", execErr)
			}
		}
	}

	DB = db
	log.Println("Database connected!")
}
