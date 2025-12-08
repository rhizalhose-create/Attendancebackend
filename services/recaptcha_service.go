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

// recaptchaResponse represents the response from Google's siteverify API
type recaptchaResponse struct {
	Success     bool     `json:"success"`
	ChallengeTS string   `json:"challenge_ts"`
	Hostname    string   `json:"hostname"`
	ErrorCodes  []string `json:"error-codes"`
	Score       float64  `json:"score,omitempty"`
	Action      string   `json:"action,omitempty"`
}

// init logs presence of the recaptcha secret (do not log secret value)
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

// VerifyRecaptcha verifies the provided token with Google's reCAPTCHA API.
// - token: the client token (from frontend)
// - remoteIP: optional remote IP string (can be empty)
// - expectedAction: the action name you expect (e.g., "login", "register", "forgot_password")
// Returns (true, nil) when verification passes, (false, nil) when token is invalid or fails checks
// Returns (false, error) on network/decoding/internal errors.
func VerifyRecaptcha(token string, remoteIP string, expectedAction string) (bool, error) {
	// Note: secret presence is logged at package init to avoid logging it per-request
	// Accept either environment variable names for secret to be flexible
	secret := strings.TrimSpace(os.Getenv("RECAPTCHA_SECRET"))
	if secret == "" {
		secret = strings.TrimSpace(os.Getenv("RECAPTCHA_SECRET_KEY"))
	}
	// If secret is not set, skip verification (development convenience)
	if secret == "" {
		return true, nil
	}

	// Reject empty-like tokens (some clients may send literal "null" or "undefined")
	token = strings.TrimSpace(token)
	if token == "" || token == "null" || token == "undefined" {
		// Treat as client error: return false with no internal error so caller can map to 400 Bad Request
		return false, nil
	}

	// Minimum acceptable score (default 0.5). Allow override with env var RECAPTCHA_MIN_SCORE
	minScore := 0.5
	if s := strings.TrimSpace(os.Getenv("RECAPTCHA_MIN_SCORE")); s != "" {
		if v, err := strconv.ParseFloat(s, 64); err == nil {
			minScore = v
		}
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

	var rr recaptchaResponse
	if err := json.NewDecoder(resp.Body).Decode(&rr); err != nil {
		log.Printf("recaptcha decode error: %v", err)
		return false, fmt.Errorf("invalid recaptcha response: %w", err)
	}

	// Debug: log what Google returned (do not log secrets)
	log.Printf("recaptcha siteverify: success=%v action=%q score=%.3f errors=%v", rr.Success, rr.Action, rr.Score, rr.ErrorCodes)

	// If siteverify returned false -> treat as verification failure (client error)
	if !rr.Success {
		log.Printf("recaptcha verification failed: errors=%v", rr.ErrorCodes)
		return false, nil
	}

	// For v3, check score threshold when present
	if rr.Score < minScore {
		log.Printf("recaptcha low score: %.3f (min %.3f) action=%q", rr.Score, minScore, rr.Action)
		return false, nil
	}

	// If an expected action was provided, ensure it matches
	if expectedAction != "" && rr.Action != "" && rr.Action != expectedAction {
		log.Printf("recaptcha action mismatch: got=%q expected=%q", rr.Action, expectedAction)
		return false, nil
	}

	// Passed all checks
	return true, nil
}
