# Automatic Token Flow - Visual Diagram

## Registration Flow with Automatic Token Passing

```
┌─────────────────────────────────────────────────────────────┐
│ FRONTEND                                                    │
└─────────────────────────────────────────────────────────────┘
         │
         │ 1. User Registration Data
         ▼
    ┌──────────────────┐
    │ POST /register   │
    └──────────────────┘
         │
         │ Returns: token + student_id
         ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Registration Success                               │
│ ✅ Pending user created                                    │
│ ✅ Verification code sent to email                         │
│ ✅ JWT token AUTO-GENERATED                                │
└─────────────────────────────────────────────────────────────┘
         │
         │ 2. User inputs verification code from email
         │    and uses token from Step 1
         ▼
    ┌──────────────────────────────┐
    │ POST /reg/verify             │
    │ Header: Authorization: Bearer │ (token from Step 1)
    │ Body: { code: "123456" }     │
    └──────────────────────────────┘
         │
         │ Validates token + code
         ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Email Verified                                      │
│ ✅ Pending user moved to users table                        │
│ ✅ User is now active and verified                          │
│ ✅ Can now login                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Forgot Password Flow with Automatic Token Passing

```
┌─────────────────────────────────────────────────────────────┐
│ FRONTEND                                                    │
└─────────────────────────────────────────────────────────────┘
         │
         │ 1. User Email
         ▼
    ┌─────────────────────────────┐
    │ POST /fgtp/forgot-password  │
    │ Body: { email }             │
    └─────────────────────────────┘
         │
         │ Returns: token (15 min expiry)
         ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Reset Code Sent                                     │
│ ✅ Reset code generated and emailed                         │
│ ✅ JWT token AUTO-GENERATED                                │
│ ⏱️  Token expires in 15 minutes                             │
└─────────────────────────────────────────────────────────────┘
         │
         │ 2. User inputs reset code from email
         │    uses token from Step 1
         ▼
    ┌──────────────────────────────────┐
    │ POST /fgtp/verify-reset-code     │
    │ Header: Authorization: Bearer... │ (token from Step 1)
    │ Body: { code: "123456" }         │
    └──────────────────────────────────┘
         │
         │ Returns: same token (for next step)
         ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Reset Code Verified                                 │
│ ✅ Code validated from database                            │
│ ✅ Token AUTOMATICALLY returned for next step              │
│ ✅ Code marked as verified but not used yet                │
└─────────────────────────────────────────────────────────────┘
         │
         │ 3. User enters new password
         │    uses token from Step 2
         ▼
    ┌──────────────────────────────────┐
    │ POST /fgtp/reset-password        │
    │ Header: Authorization: Bearer... │ (token from Step 2)
    │ Body: {                           │
    │   new_password: "...",           │
    │   confirm_new_password: "..."    │
    │ }                                │
    └──────────────────────────────────┘
         │
         │ Validates token + updates password
         ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Password Reset Complete                             │
│ ✅ New password saved (hashed)                              │
│ ✅ Reset code marked as used                                │
│ ✅ Confirmation email sent                                  │
│ ✅ User can now login with new password                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Token Flow Summary

### Key Features:
- ✅ **Zero Manual Token Management** - Tokens are auto-generated and passed
- ✅ **Secure** - Tokens expire automatically, codes can only be used once
- ✅ **Seamless** - Frontend just follows the response tokens from each step
- ✅ **Clean** - No need to store tokens manually, each step provides the next token

### Token Lifecycle:

```
Registration:
create account → generate token (24h) → send code → verify with token

Password Reset:
request reset → generate token (15m) → send code → verify code with token
           → use same token → reset password with token
```

### Timeouts:
- 🕐 Email Verification Token: **24 hours**
- 🕐 Password Reset Token: **15 minutes**
- 🕐 Verification Code: **15 minutes**
- 🕐 Reset Code: **15 minutes**

