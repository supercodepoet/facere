# Data Model: User Authentication

**Branch**: `001-user-auth` | **Date**: 2026-03-05

## Entity Relationship Overview

```text
User (1) ─── (N) Session
User (1) ─── (N) OAuthIdentity
User (1) ─── (0..1) TwoFactorCredential
User (1) ─── (0..N) RecoveryCode
```

## Entities

### User

Primary entity representing an authenticated individual in Facere.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| name | string | NOT NULL, max 255 | Single name field |
| email_address | string | NOT NULL, UNIQUE (case-insensitive) | Normalized to lowercase before save |
| password_digest | string | NOT NULL (nullable for OAuth-only users) | bcrypt hash via `has_secure_password` |
| terms_accepted_at | datetime | NOT NULL | Timestamp of TOS/PP acceptance |
| email_verified_at | datetime | NULL | NULL = unverified |
| email_verification_grace_expires_at | datetime | NULL | Set to created_at + 24h on creation |
| failed_login_attempts | integer | NOT NULL, default: 0 | Reset on successful login |
| lockout_count | integer | NOT NULL, default: 0 | Tracks consecutive lockout events for escalation; reset on successful login |
| locked_until | datetime | NULL | NULL = not locked |
| created_at | datetime | NOT NULL | Rails timestamp |
| updated_at | datetime | NOT NULL | Rails timestamp |

**Indexes**:
- `UNIQUE INDEX` on `email_address`

**Validations**:
- `name`: presence, max length 255
- `email_address`: presence, uniqueness (case-insensitive), format
  (valid email pattern)
- `password`: presence on create (unless OAuth-only), min 8 chars,
  must contain uppercase, lowercase, digit, and special character
- `password_confirmation`: must match password
- `terms_accepted_at`: presence on create

**Token Generation** (Rails `generates_token_for`):
- `:email_verification` - expires in 24 hours, scoped to email
- `:password_reset` - expires in 2 hours, scoped to password_digest

**State Transitions**:
- Unverified → Verified (via email verification link)
- Active → Locked (via failed login attempts exceeding threshold)
- Locked → Active (via lockout timer expiry)
- Active → Locked (via email verification grace period expiry)

**Methods**:
- `email_verified?` → boolean
- `within_verification_grace_period?` → boolean
- `locked?` → boolean
- `lock_account!(duration)` → void
- `reset_failed_login_attempts!` → void
- `increment_failed_login_attempts!` → void (locks if threshold hit)
- `two_factor_enabled?` → boolean

### Session

Database-backed session tracking (from Rails auth generator).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| user_id | integer | NOT NULL, FK → users | |
| ip_address | string | NULL | Recorded at creation |
| user_agent | string | NULL | Recorded at creation |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `INDEX` on `user_id`

**Associations**:
- `belongs_to :user`

### OAuthIdentity

Links a User to a third-party OAuth provider.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| user_id | integer | NOT NULL, FK → users | |
| provider | string | NOT NULL | e.g., "google", "facebook", "apple" |
| uid | string | NOT NULL | Provider's unique user identifier |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `UNIQUE INDEX` on `[provider, uid]`
- `INDEX` on `user_id`

**Validations**:
- `provider`: presence, inclusion in allowed providers
- `uid`: presence, uniqueness scoped to provider

**Associations**:
- `belongs_to :user`

### TwoFactorCredential

TOTP configuration for a User's 2FA setup.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| user_id | integer | NOT NULL, FK → users, UNIQUE | One per user |
| otp_secret | string | NOT NULL | Encrypted TOTP secret key |
| enabled | boolean | NOT NULL, default: false | Active only after first successful verification |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `UNIQUE INDEX` on `user_id`

**Validations**:
- `otp_secret`: presence
- `user_id`: uniqueness

**Associations**:
- `belongs_to :user`

**Encryption**:
- `otp_secret` encrypted at rest using Rails Active Record Encryption

**Methods**:
- `provisioning_uri(account_name)` → string (otpauth:// URI)
- `verify_code(code)` → boolean (with drift tolerance)

### RecoveryCode

One-time-use backup codes for 2FA recovery.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| user_id | integer | NOT NULL, FK → users | |
| code_digest | string | NOT NULL | bcrypt hash of the code |
| used_at | datetime | NULL | NULL = unused |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `INDEX` on `user_id`

**Validations**:
- `code_digest`: presence
- `user_id`: presence

**Associations**:
- `belongs_to :user`

**Methods**:
- `used?` → boolean
- `consume!` → void (sets used_at timestamp)
- Class method: `generate_for(user, count: 10)` → array of plaintext
  codes (displayed once, stored as digests)

## Notes

- Password reset tokens use Rails `generates_token_for` (no separate
  table needed; tokens are signed and time-limited)
- Email verification tokens also use `generates_token_for` (no
  separate table needed)
- Recovery codes are hashed with bcrypt like passwords; the plaintext
  is shown to the user once and never stored
- All sensitive fields (`otp_secret`) use Active Record Encryption
- Email addresses are normalized to lowercase before storage
- The User model does NOT require a password when the user was
  created via OAuth only (they may never set one)
