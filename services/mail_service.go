// services/mail.go

package services

import (
	"gopkg.in/gomail.v2"
	"os"
	"strconv"
)

func SendEmail(to string, subject string, body string) error {
	m := gomail.NewMessage()
	m.SetHeader("From", os.Getenv("SMTP_USER"))
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/html", body)

	d := gomail.NewDialer(
		os.Getenv("SMTP_HOST"),
		getSMTPPort(),
		os.Getenv("SMTP_USER"),
		os.Getenv("SMTP_PASS"),
	)

	return d.DialAndSend(m)
}

func getSMTPPort() int {
    port := os.Getenv("SMTP_PORT")
    if portInt, err := strconv.Atoi(port); err == nil {
        return portInt
    }
    return 587
}
