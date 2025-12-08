package middleware

import (
	"github.com/gofiber/fiber/v2"
)

// SecurityHeaders adds comprehensive security headers with modern design
func SecurityHeaders(c *fiber.Ctx) error {
	// Prevent clickjacking
	c.Set("X-Frame-Options", "DENY")
	
	// Prevent MIME type sniffing
	c.Set("X-Content-Type-Options", "nosniff")
	
	// Enable XSS protection
	c.Set("X-XSS-Protection", "1; mode=block")
	
	// Enforce HTTPS in production
	c.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
	
	// Content Security Policy - More permissive for API but still secure
	c.Set("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' *;")
	
	// Referrer Policy
	c.Set("Referrer-Policy", "strict-origin-when-cross-origin")
	
	// Permissions Policy
	c.Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
	
	// Additional security headers
	c.Set("X-Permitted-Cross-Domain-Policies", "none")
	c.Set("X-Download-Options", "noopen")
	c.Set("X-DNS-Prefetch-Control", "off")
	
	// Modern API headers
	c.Set("X-API-Version", "1.0")
	c.Set("X-Request-ID", c.Get("X-Request-ID")) // Preserve if exists
	
	return c.Next()
}

