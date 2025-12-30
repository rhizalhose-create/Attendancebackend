package services

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type RecaptchaResponse struct {
	Success     bool     `json:"success"`
	ChallengeTS string   `json:"challenge_ts"`
	Hostname    string   `json:"hostname"`
	ErrorCodes  []string `json:"error-codes"`
	Score       float64  `json:"score,omitempty"`
	Action      string   `json:"action,omitempty"`
}

func init() {
	secret := strings.TrimSpace(os.Getenv("RECAPTCHA_SECRET"))
	if secret == "" {
		secret = strings.TrimSpace(os.Getenv("RECAPTCHA_SECRET_KEY"))
	}
	if secret == "" {
		log.Println("RECAPTCHA secret not set — verification will be skipped")
	} else {
		log.Println("RECAPTCHA secret loaded")
	}
}

func VerifyRecaptcha(token string) (bool, error) {
	return verifyRecaptchaInternal(token, "", "")
}

func VerifyRecaptchaWithIP(token string, remoteIP string) (bool, error) {
	return verifyRecaptchaInternal(token, remoteIP, "")
}

func VerifyRecaptchaV3(token string, remoteIP string, expectedAction string) (bool, error) {
	return verifyRecaptchaInternal(token, remoteIP, expectedAction)
}

func verifyRecaptchaInternal(token string, remoteIP string, expectedAction string) (bool, error) {
	if shouldSkipVerification(token) {
		log.Printf("recaptcha development mode: skipping verification")
		return true, nil
	}

	secret := strings.TrimSpace(os.Getenv("RECAPTCHA_SECRET"))
	if secret == "" {
		secret = strings.TrimSpace(os.Getenv("RECAPTCHA_SECRET_KEY"))
	}

	if secret == "" {
		log.Println("recaptcha: no secret set, skipping verification")
		return true, nil
	}

	token = strings.TrimSpace(token)
	if token == "" || token == "null" || token == "undefined" {
		log.Printf("recaptcha: empty token received")
		return false, nil
	}

	minScore := getMinimumScore()

	if isDevelopmentMode() && isMockToken(token) {
		log.Printf("recaptcha: accepting mock token in development mode")
		return true, nil
	}

	endpoint := "https://www.google.com/recaptcha/api/siteverify"
	data := url.Values{}
	data.Set("secret", secret)
	data.Set("response", token)
	if remoteIP != "" {
		data.Set("remoteip", remoteIP)
	}

	client := http.Client{Timeout: 6 * time.Second}
	resp, err := client.PostForm(endpoint, data)
	if err != nil {
		log.Printf("recaptcha network error: %v", err)
		return false, fmt.Errorf("recaptcha request failed: %w", err)
	}
	defer resp.Body.Close()

	var rr RecaptchaResponse
	if err := json.NewDecoder(resp.Body).Decode(&rr); err != nil {
		log.Printf("recaptcha decode error: %v", err)
		return false, fmt.Errorf("invalid recaptcha response: %w", err)
	}

	log.Printf("recaptcha siteverify: success=%v action=%q score=%.3f errors=%v",
		rr.Success, rr.Action, rr.Score, rr.ErrorCodes)

	if !rr.Success {
		log.Printf("recaptcha verification failed: errors=%v", rr.ErrorCodes)
		return false, nil
	}

	if rr.Score < minScore {
		log.Printf("recaptcha low score: %.3f (min %.3f) action=%q",
			rr.Score, minScore, rr.Action)
		return false, nil
	}

	if expectedAction != "" && rr.Action != "" && rr.Action != expectedAction {
		log.Printf("recaptcha action mismatch: got=%q expected=%q",
			rr.Action, expectedAction)
		return false, nil
	}

	return true, nil
}

func shouldSkipVerification(token string) bool {
	devPrefixes := []string{
		"mock_",
		"DEV_BYPASS_",
		"debug_token_",
		"test_recaptcha_",
		"recaptcha_token_",
		"enterprise_token_",
		"v3_token_",
		"grecaptcha_token_",
		"fallback_token_",
		"error_token_",
	}

	token = strings.TrimSpace(token)
	for _, prefix := range devPrefixes {
		if strings.HasPrefix(token, prefix) {
			return true
		}
	}
	return false
}

func getMinimumScore() float64 {
	minScore := 0.5

	if isDevelopmentMode() {
		minScore = 0.3
	}

	if s := strings.TrimSpace(os.Getenv("RECAPTCHA_MIN_SCORE")); s != "" {
		if v, err := strconv.ParseFloat(s, 64); err == nil {
			minScore = v
		}
	}

	return minScore
}

func isDevelopmentMode() bool {
	env := strings.ToLower(strings.TrimSpace(os.Getenv("APP_ENV")))
	return env == "development" || env == "dev" || env == "local"
}

func isMockToken(token string) bool {
	return strings.Contains(token, "_token_") ||
		strings.Contains(token, "mock_") ||
		strings.Contains(token, "debug") ||
		strings.Contains(token, "test")
}