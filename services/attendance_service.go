// services/attendance_service.go
package services

import (
	"attendance-system/connection"
	"attendance-system/models"
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	StudentWhere         = "student_id = ?"
	EventWhere           = "event_id = ?"
	EventAndStudentWhere = "event_id = ? AND student_id = ?"
	StatusWhere          = "status = ?"
)

// Sentinel error returned when a student is not allowed to enter a tagged event
var ErrEventAccessDenied = errors.New("you are not allowed to enter this event")

// MarkAttendance marks attendance for a student in an event (check-in or check-out)
func MarkAttendance(req models.AttendanceRequest, markedBy, markedByRole string) (*models.Attendance, error) {
	// Validate and load required data
	if err := validateAction(req.Action); err != nil {
		return nil, err
	}

	event, err := loadEventByID(req.EventID)
	if err != nil {
		return nil, err
	}

	studentID := resolveStudentID(req.StudentID, markedBy)
	student, err := loadStudentByID(studentID)
	if err != nil {
		return nil, err
	}

	// Enforce course-tag restrictions (students only)
	if err := enforceEventCourseAccess(event, student, markedByRole); err != nil {
		return nil, err
	}

	now := time.Now()
	attendance, isNew := findOrInitAttendance(req, studentID, markedBy, markedByRole, now)

	// Handle actions via small helpers
	switch req.Action {
	case "check_in":
		if err := applyCheckIn(&attendance, now, event, student, markedByRole); err != nil {
			return nil, err
		}
	case "check_out":
		if err := applyCheckOut(&attendance, now, event, student); err != nil {
			return nil, err
		}
	}

	// Persist attendance (create or update)
	if err := persistAttendance(&attendance, isNew); err != nil {
		return nil, err
	}

	// Attach student info to the returned attendance so callers (e.g., admin scan)
	// can immediately show the student's name without an extra request.
	attendance.Student = student
	return &attendance, nil
}

// determineTimeStatus determines if student is early, on_time, or late
func determineTimeStatus(actualTime time.Time, expectedTime time.Time, gracePeriod time.Duration) string {
	// Allow 5 minutes early as "on_time"
	earlyThreshold := expectedTime.Add(-5 * time.Minute)
	lateThreshold := expectedTime.Add(gracePeriod)

	if actualTime.Before(earlyThreshold) {
		return "early"
	} else if actualTime.After(lateThreshold) {
		return "late"
	} else {
		return "on_time"
	}
}

// applyCheckIn applies check-in logic to the attendance record
// Students can check in starting 2 hours before event start until event ends
// Faculty/Admin can check in anytime (for setup/testing)
func applyCheckIn(att *models.Attendance, now time.Time, event models.Event, student models.User, markedByRole string) error {
	if att.CheckInTime != nil {
		return errors.New("already checked in")
	}

	// Faculty and admin can scan anytime (for setup/testing purposes)
	if markedByRole == "faculty" || markedByRole == "admin" || markedByRole == "superadmin" {
		// Admins/faculty can scan anytime, but still within event availability
		// Allow scanning up to 1 day after event ends
		if now.After(event.EndTime.Add(24 * time.Hour)) {
			return errors.New("event has ended more than 24 hours ago. Check-in is no longer allowed")
		}
	} else {
		// Students: Allow check-in 30 minutes before event start until event ends (real-time scanning)
		earliestCheckIn := event.StartTime.Add(-30 * time.Minute)
		if now.Before(earliestCheckIn) {
			minutesUntilCheckIn := earliestCheckIn.Sub(now).Minutes()
			return fmt.Errorf("event check-in not yet available. Available in %.0f minutes", minutesUntilCheckIn)
		}

		// Allow check-in until event actually ends (real-time scanning during event)
		if now.After(event.EndTime) {
			return errors.New("event has already ended. Check-in is no longer allowed")
		}
	}

	att.CheckInTime = &now
	checkInStatus := determineTimeStatus(now, event.StartTime, 15*time.Minute)
	att.CheckInStatus = checkInStatus
	if checkInStatus == "late" {
		att.Status = "late"
	} else {
		att.Status = "present"
	}
	go sendCheckInNotification(event, student, now, checkInStatus)
	return nil
}

// applyCheckOut applies check-out logic to the attendance record
func applyCheckOut(att *models.Attendance, now time.Time, event models.Event, student models.User) error {
	if att.CheckInTime == nil {
		return errors.New("must check in first before checking out")
	}
	if att.CheckOutTime != nil {
		return errors.New("already checked out")
	}
	att.CheckOutTime = &now
	checkOutStatus := determineTimeStatus(now, event.EndTime, 0)
	att.CheckOutStatus = checkOutStatus
	go sendCheckOutNotification(event, student, now, checkOutStatus)
	return nil
}

// --- Helper functions extracted to simplify MarkAttendance ---
func validateAction(action string) error {
	if action != "check_in" && action != "check_out" {
		return errors.New("action must be 'check_in' or 'check_out'")
	}
	return nil
}

func loadEventByID(eventID uint) (models.Event, error) {
	var event models.Event
	if err := connection.DB.First(&event, eventID).Error; err != nil {
		return event, errors.New("event not found")
	}
	if !event.IsActive {
		return event, errors.New("event is not active")
	}
	return event, nil
}

func resolveStudentID(requested, markedBy string) string {
	if requested == "" {
		return markedBy
	}
	return requested
}

func loadStudentByID(studentID string) (models.User, error) {
	var student models.User
	if err := connection.DB.Where(StudentWhere, studentID).First(&student).Error; err != nil {
		return student, errors.New("student not found")
	}
	return student, nil
}

func findOrInitAttendance(req models.AttendanceRequest, studentID, markedBy, markedByRole string, now time.Time) (models.Attendance, bool) {
	var attendance models.Attendance
	if err := connection.DB.Where(EventAndStudentWhere, req.EventID, studentID).First(&attendance).Error; err != nil {
		attendance = models.Attendance{
			EventID:      req.EventID,
			StudentID:    studentID,
			Status:       "present",
			MarkedAt:     now,
			MarkedBy:     markedBy,
			MarkedByRole: markedByRole,
			Method:       req.Method,
			Latitude:     req.Latitude,
			Longitude:    req.Longitude,
			Notes:        req.Notes,
		}
		if attendance.Method == "" {
			attendance.Method = "qr_scan"
		}

		// Defensive: ensure ID is zero so DB assigns it
		attendance.ID = 0
		return attendance, true
	}
	return attendance, false
}

// createAttendanceRaw inserts an attendance row using raw SQL omitting the id
// column so the DB sequence assigns the primary key. It retries once after
// resyncing the sequence if a duplicate-key error occurs.
func createAttendanceRaw(att *models.Attendance) error {
	// Use GORM create while omitting the ID field so the DB assigns it.
	if err := connection.DB.Omit("id").Create(att).Error; err != nil {
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
			// Attempt to resync sequence and retry once
			_ = connection.DB.Exec("SELECT setval(pg_get_serial_sequence('attendances','id'), (SELECT COALESCE(MAX(id),1) FROM attendances))")
			if err2 := connection.DB.Omit("id").Create(att).Error; err2 != nil {
				return fmt.Errorf("failed to mark attendance after sequence fix: %v", err2)
			}
			return nil
		}
		return fmt.Errorf("failed to mark attendance: %v", err)
	}
	return nil
}

// enforceEventCourseAccess returns error when a student is not allowed to enter a tagged event.
func enforceEventCourseAccess(event models.Event, student models.User, markedByRole string) error {
	if event.TaggedCoursesCSV == "" {
		return nil
	}
	if markedByRole != "student" {
		// admins/faculty bypass
		return nil
	}

	parts := strings.Split(event.TaggedCoursesCSV, ",")
	userCourse := strings.ToUpper(strings.TrimSpace(student.Course))
	userYearLevel := strings.ToUpper(strings.TrimSpace(student.YearLevel))

	// Check if student's course matches any tagged course
	courseAllowed := false
	for _, c := range parts {
		if strings.ToUpper(strings.TrimSpace(c)) == userCourse {
			courseAllowed = true
			break
		}
	}

	if !courseAllowed {
		return ErrEventAccessDenied
	}

	// If event specifies year level, also check year level
	if event.YearLevel != "" && strings.ToUpper(strings.TrimSpace(event.YearLevel)) != userYearLevel {
		return ErrEventAccessDenied
	}

	return nil
}

// persistAttendance saves or creates the attendance record. If isNew is true,
// it creates the record (with sequence-resync retry); otherwise it updates.
func persistAttendance(att *models.Attendance, isNew bool) error {
	if isNew {
		return createAttendanceRaw(att)
	}
	if err := connection.DB.Save(att).Error; err != nil {
		return fmt.Errorf("failed to update attendance: %v", err)
	}
	return nil
}

// sendCheckInNotification sends email to superadmin, admin, and event creator when student checks in
func sendCheckInNotification(event models.Event, student models.User, checkInTime time.Time, status string) {
	// Get superadmin and admin emails
	var admins []models.User
	connection.DB.Where("role IN ?", []string{"superadmin", "admin"}).Find(&admins)

	// Add event creator if not already in list
	var creator models.User
	if connection.DB.Where(StudentWhere, event.CreatedBy).First(&creator).Error == nil {
		found := false
		for _, admin := range admins {
			if admin.StudentID == creator.StudentID {
				found = true
				break
			}
		}
		if !found {
			admins = append(admins, creator)
		}
	}

	// Format time
	timeStr := checkInTime.Format("January 2, 2006 3:04 PM")
	statusText := map[string]string{
		"early":   "Early (arrived before scheduled time)",
		"on_time": "On Time",
		"late":    "Late",
	}[status]

	content := fmt.Sprintf(`<p><strong>Event:</strong> %s</p>
		<p><strong>Student:</strong> %s %s (%s)</p>
		<p><strong>Student ID:</strong> %s</p>
		<p><strong>Check-In Time:</strong> %s</p>
		<p><strong>Status:</strong> %s</p>
		<p><strong>Location:</strong> %s</p>`, event.Title, student.FirstName, student.LastName, student.Username, student.StudentID, timeStr, statusText, event.Location)

	footer := `<p class="muted">This is an automated notification from the Attendance System.</p>`

	htmlBody := BuildHTMLEmail("Student check-in", "Student Check-In Notification", content, footer)

	// Send email to all admins
	for _, admin := range admins {
		if admin.Email != "" {
			SendEmail(admin.Email, fmt.Sprintf("Check-In: %s %s - %s", student.FirstName, student.LastName, event.Title), htmlBody)
		}
	}
}

// sendCheckOutNotification sends email to superadmin, admin, and event creator when student checks out
func sendCheckOutNotification(event models.Event, student models.User, checkOutTime time.Time, status string) {
	// Get superadmin and admin emails
	var admins []models.User
	connection.DB.Where("role IN ?", []string{"superadmin", "admin"}).Find(&admins)

	// Add event creator if not already in list
	var creator models.User
	if connection.DB.Where(StudentWhere, event.CreatedBy).First(&creator).Error == nil {
		found := false
		for _, admin := range admins {
			if admin.StudentID == creator.StudentID {
				found = true
				break
			}
		}
		if !found {
			admins = append(admins, creator)
		}
	}

	// Format time
	timeStr := checkOutTime.Format("January 2, 2006 3:04 PM")
	statusText := map[string]string{
		"early":   "Left Early",
		"on_time": "On Time",
		"late":    "Left Late",
	}[status]

	content := fmt.Sprintf(`<p><strong>Event:</strong> %s</p>
		<p><strong>Student:</strong> %s %s (%s)</p>
		<p><strong>Student ID:</strong> %s</p>
		<p><strong>Check-Out Time:</strong> %s</p>
		<p><strong>Status:</strong> %s</p>
		<p><strong>Location:</strong> %s</p>`, event.Title, student.FirstName, student.LastName, student.Username, student.StudentID, timeStr, statusText, event.Location)

	footer := `<p class="muted">This is an automated notification from the Attendance System.</p>`

	htmlBody := BuildHTMLEmail("Student check-out", "Student Check-Out Notification", content, footer)

	// Send email to all admins
	for _, admin := range admins {
		if admin.Email != "" {
			SendEmail(admin.Email, fmt.Sprintf("Check-Out: %s %s - %s", student.FirstName, student.LastName, event.Title), htmlBody)
		}
	}
}

// GetAttendanceByEvent retrieves all attendance records for an event
func GetAttendanceByEvent(eventID uint) ([]models.Attendance, error) {
	var attendances []models.Attendance
	if err := connection.DB.Preload("Student").Preload("Event").
		Where("event_id = ?", eventID).
		Order("marked_at DESC").
		Find(&attendances).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch attendance: %v", err)
	}
	return attendances, nil
}

// GetAttendanceByStudent retrieves all attendance records for a student
func GetAttendanceByStudent(studentID string, filters map[string]interface{}) ([]models.Attendance, error) {
	var attendances []models.Attendance
	query := connection.DB.Preload("Event").Preload("Student").
		Where(StudentWhere, studentID)

	// Apply filters
	if eventID, ok := filters["event_id"].(uint); ok && eventID > 0 {
		query = query.Where(EventWhere, eventID)
	}
	if status, ok := filters["status"].(string); ok && status != "" {
		query = query.Where(StatusWhere, status)
	}
	if startDate, ok := filters["start_date"].(string); ok && startDate != "" {
		query = query.Where("created_at >= ?", startDate)
	}
	if endDate, ok := filters["end_date"].(string); ok && endDate != "" {
		query = query.Where("created_at <= ?", endDate)
	}

	if err := query.Order("marked_at DESC").Find(&attendances).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch attendance: %v", err)
	}
	return attendances, nil
}

// GetAttendanceStats calculates attendance statistics
func GetAttendanceStats(studentID string, eventID *uint) (*models.AttendanceStats, error) {
	query := connection.DB.Model(&models.Attendance{})

	if eventID != nil {
		query = query.Where(EventWhere, *eventID)
	}

	if studentID != "" {
		query = query.Where(StudentWhere, studentID)
	}

	var total int64
	var presentCount, absentCount, lateCount, excusedCount int64

	query.Count(&total)

	query.Where(StatusWhere, "present").Count(&presentCount)
	query.Where(StatusWhere, "absent").Count(&absentCount)
	query.Where(StatusWhere, "late").Count(&lateCount)
	query.Where(StatusWhere, "excused").Count(&excusedCount)

	var attendanceRate float64
	if total > 0 {
		attendanceRate = float64(presentCount+lateCount+excusedCount) / float64(total) * 100
	}

	stats := &models.AttendanceStats{
		TotalEvents:    int(total),
		PresentCount:   int(presentCount),
		AbsentCount:    int(absentCount),
		LateCount:      int(lateCount),
		ExcusedCount:   int(excusedCount),
		AttendanceRate: attendanceRate,
	}

	return stats, nil
}

// UpdateAttendanceStatus updates attendance status (for admin/faculty)
func UpdateAttendanceStatus(attendanceID uint, status, notes string, updatedBy string) (*models.Attendance, error) {
	var attendance models.Attendance
	if err := connection.DB.First(&attendance, attendanceID).Error; err != nil {
		return nil, errors.New("attendance record not found")
	}

	// Check permissions
	var user models.User
	if err := connection.DB.Where(StudentWhere, updatedBy).First(&user).Error; err != nil {
		return nil, errors.New("unauthorized")
	}

	if user.Role != "superadmin" && user.Role != "admin" && user.Role != "faculty" {
		return nil, errors.New("unauthorized: only admin or faculty can update attendance")
	}

	// Update status
	validStatuses := map[string]bool{
		"present": true,
		"absent":  true,
		"late":    true,
		"excused": true,
	}

	if !validStatuses[status] {
		return nil, errors.New("invalid status. Valid: present, absent, late, excused")
	}

	updates := map[string]interface{}{
		"status":         status,
		"marked_by":      updatedBy,
		"marked_by_role": user.Role,
		"updated_at":     time.Now(),
	}
	if notes != "" {
		updates["notes"] = notes
	}

	if err := connection.DB.Model(&models.Attendance{}).Where("id = ?", attendanceID).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("failed to update attendance: %v", err)
	}

	// Return the updated record
	if err := connection.DB.First(&attendance, attendanceID).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch updated attendance: %v", err)
	}

	return &attendance, nil
}
