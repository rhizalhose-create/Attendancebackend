// controller/event_controller.go
package controller

import (
	"attendance-system/connection"
	"attendance-system/models"
	"attendance-system/services"
	"attendance-system/utils"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// CreateEvent creates a new event
func CreateEvent(c *fiber.Ctx) error {
	req := new(models.EventRequest)
	if err := c.BodyParser(req); err != nil {
		// Try to be permissive: if BodyParser fails (client may have sent form-data),
		// continue and attempt to read form fields where possible. We'll only fail
		// later if required fields are missing.
		// Note: keep original behavior for strict JSON clients.
	}

	// Fallback: support `tagged_courses` as a CSV form value when clients send form-data
	if len(req.TaggedCourses) == 0 {
		if raw := c.FormValue("tagged_courses"); raw != "" {
			parts := strings.Split(raw, ",")
			for _, p := range parts {
				p = strings.ToUpper(strings.TrimSpace(p))
				if p != "" {
					req.TaggedCourses = append(req.TaggedCourses, p)
				}
			}
		}
	}

	// Validate required fields
	if req.Title == "" || req.EventDate == "" || req.StartTime == "" || req.EndTime == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Title, event_date, start_time, and end_time are required"})
	}

	// Get user from context (set by auth middleware)
	user, ok := c.Locals("user").(models.User)
	if !ok {
		// Fallback: try to get from query/header (for backward compatibility)
		studentID := c.Get(utils.HeaderStudentID)
		if studentID == "" {
			return c.Status(401).JSON(fiber.Map{"error": utils.ErrUnauthorized})
		}
		var dbUser models.User
		if err := connection.DB.Where("student_id = ?", studentID).First(&dbUser).Error; err != nil {
			return c.Status(401).JSON(fiber.Map{"error": utils.ErrUserNotFound})
		}
		user = dbUser
	}

	event, err := services.CreateEvent(*req, user.StudentID, user.Role)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(fiber.Map{
		"message": "Event created successfully",
		"event":   event,
	})
}

// GetEvent retrieves a single event
func GetEvent(c *fiber.Ctx) error {
	eventIDStr := c.Params("id")
	eventID, err := strconv.ParseUint(eventIDStr, 10, 32)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": utils.ErrInvalidEventID})
	}

	event, err := services.GetEvent(uint(eventID))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"event": event,
	})
}

// GetAllEvents retrieves all events with optional filters
func GetAllEvents(c *fiber.Ctx) error {
	filters := make(map[string]interface{})

	if course := c.Query("course"); course != "" {
		filters["course"] = course
	}
	if section := c.Query("section"); section != "" {
		filters["section"] = section
	}
	if yearLevel := c.Query("year_level"); yearLevel != "" {
		filters["year_level"] = yearLevel
	}
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if isActive := c.Query("is_active"); isActive != "" {
		filters["is_active"] = isActive == "true"
	}

	events, err := services.GetAllEvents(filters)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"events": events,
		"count":  len(events),
	})
}

// GetMyEvents retrieves events for the current student
func GetMyEvents(c *fiber.Ctx) error {
	user, ok := c.Locals("user").(models.User)
	if !ok {
		studentID := c.Get("X-Student-ID")
		if studentID == "" {
			return c.Status(401).JSON(fiber.Map{"error": "Unauthorized"})
		}
		user.StudentID = studentID
	}

	// Admins/faculty/superadmin should see all events (management view).
	var events []models.Event
	var err error
	if user.Role == "superadmin" || user.Role == "admin" || user.Role == "faculty" {
		events, err = services.GetAllEvents(map[string]interface{}{})
	} else {
		events, err = services.GetEventsByStudent(user.StudentID)
	}
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"events": events,
		"count":  len(events),
	})
}

// UpdateEvent updates an event
func UpdateEvent(c *fiber.Ctx) error {
	eventIDStr := c.Params("id")
	eventID, err := strconv.ParseUint(eventIDStr, 10, 32)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": utils.ErrInvalidEventID})
	}

	req := new(models.EventRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request format"})
	}

	user, ok := c.Locals("user").(models.User)
	if !ok {
		studentID := c.Get(utils.HeaderStudentID)
		if studentID == "" {
			return c.Status(401).JSON(fiber.Map{"error": utils.ErrUnauthorized})
		}
		user.StudentID = studentID
	}

	event, err := services.UpdateEvent(uint(eventID), *req, user.StudentID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"message": "Event updated successfully",
		"event":   event,
	})
}

// DeleteEvent deletes an event (soft delete)
func DeleteEvent(c *fiber.Ctx) error {
	eventIDStr := c.Params("id")
	eventID, err := strconv.ParseUint(eventIDStr, 10, 32)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": utils.ErrInvalidEventID})
	}

	user, ok := c.Locals("user").(models.User)
	if !ok {
		studentID := c.Get(utils.HeaderStudentID)
		if studentID == "" {
			return c.Status(401).JSON(fiber.Map{"error": utils.ErrUnauthorized})
		}
		user.StudentID = studentID
	}

	if err := services.DeleteEvent(uint(eventID), user.StudentID); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"message": "Event deleted successfully",
	})
}
