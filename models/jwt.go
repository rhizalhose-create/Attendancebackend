// models/jwt.go
// JWT token claims and configuration

package models

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWTClaims contains JWT token claims with expiration
type JWTClaims struct {
	StudentID string `json:"student_id"`
	Email     string `json:"email"`
	Role      string `json:"role"`
	jwt.RegisteredClaims
}

// RefreshTokenClaims contains refresh token claims
type RefreshTokenClaims struct {
	StudentID string `json:"student_id"`
	jwt.RegisteredClaims
}

const (
	// AccessTokenExpiry is the expiration time for access tokens (15 minutes)
	AccessTokenExpiry = 15 * time.Minute
	// RefreshTokenExpiry is the expiration time for refresh tokens (7 days)
	RefreshTokenExpiry = 7 * 24 * time.Hour
)

var (
	// JWT Errors
	ErrInvalidToken = errors.New("invalid or expired token")
	ErrNoSecretKey  = errors.New("JWT_SECRET not configured")
)
