package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"log"

	"github.com/gofiber/fiber/v2"
)

func PromoteUser(c *fiber.Ctx) error {
	var req models.PromoteRequest

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	// Validate required fields
	if req.StudentID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "StudentID is required",
		})
	}

	if req.Role == "" {
		req.Role = "admin"
	}

	// Validate role
	validRoles := map[string]bool{
		"admin":   true,
		"faculty": true,
		"staff":   true,
		"student": true,
	}

	if !validRoles[req.Role] {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid role. Valid roles: admin, faculty, staff, student",
		})
	}

	db := connection.DB

	// Check if target user exists
	var targetUser models.User
	if err := db.Where("student_id = ?", req.StudentID).First(&targetUser).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	// Get superadmin from context (set by middleware)
	superadmin, ok := c.Locals("user").(models.User)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to verify admin permissions",
		})
	}

	// Prevent self-demotion
	if targetUser.StudentID == superadmin.StudentID && req.Role != "superadmin" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Superadmin cannot demote themselves",
		})
	}

	// Prevent promoting to superadmin (only seed can create superadmin)
	if req.Role == "superadmin" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Cannot promote to superadmin role",
		})
	}

	// Update role
	oldRole := targetUser.Role
	targetUser.Role = req.Role

	log.Printf("PromoteUser: targetUser.ID=%d student_id=%s", targetUser.ID, targetUser.StudentID)

	// Use a targeted update to avoid Save() creating a new record unexpectedly.
	res := db.Model(&models.User{}).Where("id = ?", targetUser.ID).Updates(map[string]interface{}{"role": req.Role})
	if res.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to update user role",
		})
	}
	if res.RowsAffected == 0 {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "No rows updated while promoting user",
		})
	}

	return c.JSON(fiber.Map{
		"message":    "User role updated successfully",
		"student_id": targetUser.StudentID,
		"old_role":   oldRole,
		"new_role":   targetUser.Role,
		"updated_by": superadmin.StudentID,
	})
}

// Get all users (for admin dashboard)
func GetAllUsers(c *fiber.Ctx) error {
	db := connection.DB

	var users []models.User
	if err := db.Find(&users).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch users",
		})
	}

	// Create safe response (without passwords)
	var response []map[string]interface{}
	for _, user := range users {
		response = append(response, map[string]interface{}{
			"student_id":  user.StudentID,
			"email":       user.Email,
			"username":    user.Username,
			"first_name":  user.FirstName,
			"last_name":   user.LastName,
			"role":        user.Role,
			"is_verified": user.IsVerified,
			"course":      user.Course,
			"year_level":  user.YearLevel,
			"section":     user.Section,
			"created_at":  user.CreatedAt,
			"verified_at": user.VerifiedAt,
		})
	}

	return c.JSON(fiber.Map{
		"users": response,
		"count": len(response),
	})
}
