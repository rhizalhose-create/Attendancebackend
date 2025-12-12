package services

const (
	RecaptchaReasonOK = "ok"
)

func VerifyRecaptcha(token string, remoteIP string, expectedAction string) (bool, string, error) {
	return true, RecaptchaReasonOK, nil
}
