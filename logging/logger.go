package logging

import (
	"fmt"
	"os"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
)

// Logger is the global logger instance
var Logger *zap.Logger

// InitLogger initializes the modern logging system
func InitLogger() error {
	// Create logs directory if it doesn't exist
	if err := os.MkdirAll("logs", 0755); err != nil {
		return err
	}

	// Generate filename with current date
	currentDate := time.Now().Format("2006-01-02")
	filename := fmt.Sprintf("logs/ATENDIFY-%s.log", currentDate)

	// Configure lumberjack for file rotation
	fileWriter := &lumberjack.Logger{
		Filename:   filename, // Date-based filename
		MaxSize:    10,
		MaxBackups: 30,
		MaxAge:     30,
		Compress:   true,
	}

	// JSON encoder for file (structured)
	fileEncoder := zapcore.NewJSONEncoder(zapcore.EncoderConfig{
		TimeKey:        "timestamp",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		FunctionKey:    zapcore.OmitKey,
		MessageKey:     "message",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	})

	// Console encoder (human-readable)
	consoleEncoder := zapcore.NewConsoleEncoder(zapcore.EncoderConfig{
		TimeKey:        "timestamp",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		FunctionKey:    zapcore.OmitKey,
		MessageKey:     "message",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.CapitalColorLevelEncoder,
		EncodeTime:     customTimeEncoder,
		EncodeDuration: zapcore.StringDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	})

	// Create cores
	fileCore := zapcore.NewCore(fileEncoder, zapcore.AddSync(fileWriter), zapcore.InfoLevel)
	consoleCore := zapcore.NewCore(consoleEncoder, zapcore.AddSync(os.Stdout), zapcore.DebugLevel)

	// Combine cores (logs go to both)
	core := zapcore.NewTee(fileCore, consoleCore)

	// Create logger
	Logger = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))

	return nil
}

// customTimeEncoder formats time in a readable way for console
func customTimeEncoder(t time.Time, enc zapcore.PrimitiveArrayEncoder) {
	enc.AppendString(t.Format("2006-01-02 15:04:05"))
}

// LogWithIP creates a logger with IP address field
func LogWithIP(ip string) *zap.Logger {
	return Logger.With(zap.String("client_ip", ip))
}

// LogRequest logs HTTP requests with IP
func LogRequest(ip, method, path string, status int, duration time.Duration) {
	Logger.Info("HTTP Request",
		zap.String("client_ip", ip),
		zap.String("method", method),
		zap.String("path", path),
		zap.Int("status", status),
		zap.Duration("duration", duration),
	)
}

// LogAuth logs authentication events
func LogAuth(ip, action, userID string, success bool) {
	level := zapcore.InfoLevel
	if !success {
		level = zapcore.WarnLevel
	}
	Logger.Log(level, "Authentication",
		zap.String("client_ip", ip),
		zap.String("action", action),
		zap.String("user_id", userID),
		zap.Bool("success", success),
	)
}

// LogSecurity logs security-related events
func LogSecurity(ip, event, details string) {
	Logger.Warn("Security Event",
		zap.String("client_ip", ip),
		zap.String("event", event),
		zap.String("details", details),
	)
}

// LogError logs errors with context
func LogError(ip string, err error, context string) {
	Logger.Error("Error",
		zap.String("client_ip", ip),
		zap.Error(err),
		zap.String("context", context),
	)
}
