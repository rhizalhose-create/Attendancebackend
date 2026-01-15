package services

import (
	"attendance-system/logging"
	"fmt"
	"html"
	"os"
	"regexp"
	"strconv"
	"strings"

	"gopkg.in/gomail.v2"
)

func SendEmail(to string, subject string, htmlBody string) error {
	plain := htmlToPlain(htmlBody)

	from := strings.TrimSpace(os.Getenv("SMTP_USER"))
	if from == "" {
		return fmt.Errorf("SMTP_USER is not set")
	}

	host := strings.TrimSpace(os.Getenv("SMTP_HOST"))
	pass := strings.TrimSpace(os.Getenv("SMTP_PASS"))

	m := gomail.NewMessage()
	m.SetHeader("From", "Attendance System <"+from+">")
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", plain)
	m.AddAlternative("text/html", htmlBody)

	d := gomail.NewDialer(
		host,
		getSMTPPort(),
		from,
		pass,
	)

	if err := d.DialAndSend(m); err != nil {
		logging.Logger.Sugar().Errorf("SMTP ERROR: %v", err)
		return err
	}

	logging.Logger.Sugar().Infof("Email sent successfully to %s", to)
	return nil
}

func getSMTPPort() int {
	port := strings.TrimSpace(os.Getenv("SMTP_PORT"))
	if portInt, err := strconv.Atoi(port); err == nil {
		return portInt
	}
	return 587
}

func htmlToPlain(s string) string {
	reScripts := regexp.MustCompile(`(?s)<(script|style)[^>]*>.*?</(script|style)>`)
	s = reScripts.ReplaceAllString(s, "")

	re := regexp.MustCompile(`<[^>]+>`)
	noTags := re.ReplaceAllString(s, " ")

	collapsed := strings.Join(strings.Fields(noTags), " ")
	return html.UnescapeString(strings.TrimSpace(collapsed))
}

func BuildHTMLEmail(preheader, heading, contentHTML, footerHTML string) string {
	template := `<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>%s</title>
</head>
<body style="background:#f5f7fb;padding:20px;">
	<span style="display:none">%s</span>
	<div style="max-width:600px;margin:auto;background:#fff;border-radius:8px;">
		<div style="background:#4f46e5;color:#fff;padding:20px;">
			<h1>%s</h1>
		</div>
		<div style="padding:24px;">
			%s
		</div>
		<div style="padding:16px;color:#6b7280;font-size:13px;">
			%s
		</div>
	</div>
</body>
</html>`

	return fmt.Sprintf(template, heading, preheader, heading, contentHTML, footerHTML)
}
