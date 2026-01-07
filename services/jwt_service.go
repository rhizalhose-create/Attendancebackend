// services/jwt_service.go
package services

import (
	"attendance-system/models"
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Import types from models for convenience
type JWTClaims = models.JWTClaims
type RefreshTokenClaims = models.RefreshTokenClaims

var (
	ErrNoSecretKey   = models.ErrNoSecretKey
	ErrInvalidToken  = models.ErrInvalidToken
	AccessTokenExpiry = models.AccessTokenExpiry
	RefreshTokenExpiry = models.RefreshTokenExpiry
)

var jwtSecret string

// init loads JWT secret from environment
func init() {
	jwtSecret = os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "dev-secret-change-in-production" // Fallback for development only
	}
}

// GenerateAccessToken creates a new JWT access token
func GenerateAccessToken(user models.User) (string, error) {
	if jwtSecret == "" {
		return "", ErrNoSecretKey
	}

	claims := JWTClaims{
		StudentID: user.StudentID,
		Email:     user.Email,
		Role:      user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(AccessTokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Subject:   user.StudentID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err)
	}

	return tokenString, nil
}

// GenerateRefreshToken creates a new JWT refresh token
func GenerateRefreshToken(user models.User) (string, error) {
	if jwtSecret == "" {
		return "", ErrNoSecretKey
	}

	claims := RefreshTokenClaims{
		StudentID: user.StudentID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(RefreshTokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Subject:   user.StudentID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", fmt.Errorf("failed to sign refresh token: %w", err)
	}

	return tokenString, nil
}

// VerifyAccessToken verifies and parses an access token
func VerifyAccessToken(tokenString string) (*JWTClaims, error) {
	if tokenString == "" {
		return nil, ErrInvalidToken
	}

	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Verify signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(jwtSecret), nil
	})

	if err != nil {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}

// VerifyRefreshToken verifies and parses a refresh token
func VerifyRefreshToken(tokenString string) (*RefreshTokenClaims, error) {
	if tokenString == "" {
		return nil, ErrInvalidToken
	}

	token, err := jwt.ParseWithClaims(tokenString, &RefreshTokenClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(jwtSecret), nil
	})

	if err != nil {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*RefreshTokenClaims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}
