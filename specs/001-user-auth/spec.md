# Feature Specification: User Authentication

**Feature Branch**: `001-user-auth`
**Created**: 2026-03-05
**Status**: Complete
**Last Updated**: 2026-03-21
**Input**: User authentication with sign in, sign up, password reset, OAuth providers, and two-factor authentication
**Test Results**: 101 tests, 305 assertions, 0 failures, 0 errors

## Clarifications

### Session 2026-03-05

- Q: Should new email/password accounts require email verification before the user can access the application? → A: Yes, email verification required with a 24-hour grace period. Users can access the app immediately after sign-up but must verify their email within 24 hours or their account is locked until verified.
- Q: How should the system handle repeated failed sign-in attempts? → A: Temporary lockout after 5 failed attempts for 15 minutes, with escalating lockout duration on repeated lockouts.
- Q: Should the name field be a single field or split into first and last name? → A: Single "Name" field (e.g., "Jane Doe") for simplicity and inclusivity.
- Q: When OAuth email matches an existing email/password account, should linking happen automatically or require verification? → A: Require the user to enter their existing account password to confirm the link.
- Q: Must users who sign up via OAuth also accept TOS and Privacy Policy? → A: Yes, show a brief acceptance screen after OAuth return before completing account creation.

## Implementation Learnings

### Session 2026-03-21

Learnings captured during implementation and testing:

- **Icons**: Use `<i>` tags with Font Awesome classes (e.g., `<i class="fa-thin fa-eye"></i>`). The thin style matches the design system.
- **Turbo Frame tab switching**: The segmented Sign In / Sign Up toggle uses Turbo Frames (`<turbo-frame id="auth_form">`). This provides seamless tab switching without full page reload while keeping each form as its own route/controller action. A fixed `min-height: 720px` on the turbo-frame wrapper prevents layout shift during tab switching.
- **OAuth providers shipped**: Google and Apple are rendered as active OAuth buttons. Facebook is configured in OmniAuth but not shown in the UI buttons partial.
- **Password validation UX**: The `form_validation_controller` Stimulus controller provides real-time password requirement checking with visual indicators. Requirements are displayed via a tooltip attached to a hint icon next to the password label, with individual requirements getting a `met` CSS class as they're satisfied.
- **2FA auto-submit**: The `two_factor_controller` Stimulus controller auto-submits the verification form when 6 digits are entered, and toggles between TOTP code and recovery code input modes.
- **Session cookies**: Authentication uses permanent signed cookies (`cookies.signed.permanent[:session_id]`) with `httponly: true` and `same_site: :lax` settings.
- **Lockout escalation**: The exponential backoff formula is `LOCKOUT_DURATION * LOCKOUT_ESCALATION_FACTOR^lockout_count` (15min * 2^n), providing escalating lockout durations across repeated lockout events.
- **Password requirements**: Enforced both client-side (Stimulus) and server-side (model validation): minimum 8 characters, at least one uppercase, one lowercase, one digit, and one special character. The `password_required?` check is conditional — OAuth-only users without a password_digest are not required to set a password.
- **Recovery codes**: 10 codes generated per 2FA setup. Stored as BCrypt digests (not plaintext). The `RecoveryCode.generate_for(user)` class method replaces any existing codes before generating new ones, and returns the plaintext codes exactly once for display.
- **Rate limiting**: Applied to `SessionsController#create` (10/min) and `RegistrationsController#create` (10/min) using Rails 8's built-in `rate_limit` macro.
- **TOTP drift tolerance**: `TwoFactorCredential#verify_code` accepts codes within ±15 seconds of the current time window using ROTP's `drift_behind` and `drift_ahead` parameters.
- **Email verification tokens**: Use Rails `generates_token_for` with 24-hour expiry, scoped to the user's email (token invalidated if email changes). Password reset tokens use the same mechanism with 2-hour expiry, scoped to password_digest (token invalidated if password changes).
- **Test architecture**: 101 tests across 18 files — model tests (45), controller integration tests (43), mailer tests (4), and system tests (13 with Capybara/Selenium). Tests run in parallel (16 processes). OmniAuth testing uses `OmniAuth.config.mock_auth` with test mode enabled. Session helper module provides `sign_in_as(user)` and `sign_out` for authenticated test contexts.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign Up with Email and Password (Priority: P1)

A new visitor arrives at Facere and wants to create an account. They see a friendly sign-up form asking for their name, email address, password, and password confirmation. They must accept the Terms of Service and Privacy Policy before submitting. Upon successful registration, they are welcomed into the application and a verification email is sent. They have 24 hours to verify their email; after that, their account is locked until verification is completed.

**Why this priority**: Without account creation, no other authentication flows are possible. This is the foundational entry point for every new user.

**Independent Test**: Can be fully tested by navigating to the sign-up page, filling out the form with valid data, and verifying the user is created and logged in.

**Acceptance Scenarios**:

1. **Given** a visitor on the sign-up page, **When** they fill in name, email, password, password confirmation, accept TOS/PP, and submit, **Then** their account is created, they are signed in to the application, and a verification email is sent.
2. **Given** a newly registered user who has not verified their email, **When** they use the application within 24 hours of sign-up, **Then** they have full access but see a persistent, non-blocking reminder to verify their email.
3. **Given** a user whose 24-hour grace period has expired without email verification, **When** they attempt to access the application, **Then** they are shown a screen requiring email verification with an option to resend the verification email.
4. **Given** a user who clicks the verification link in their email, **When** the link is valid, **Then** their email is marked as verified and any verification reminders are removed.
5. **Given** a visitor on the sign-up page, **When** they submit without filling all required fields, **Then** clear, visible error messages indicate which fields need attention.
6. **Given** a visitor on the sign-up page, **When** they enter an email that already exists, **Then** a security-aware error is shown (does not confirm the email exists, e.g., "Unable to create account with this information").
7. **Given** a visitor on the sign-up page, **When** they enter a password that does not meet policy, **Then** clear feedback explains what the password requirements are.
8. **Given** a visitor on the sign-up page, **When** password and confirmation do not match, **Then** an error clearly indicates the mismatch.
9. **Given** a visitor on the sign-up page, **When** they do not accept TOS and PP, **Then** the form cannot be submitted and a message explains acceptance is required.

---

### User Story 2 - Sign In with Email and Password (Priority: P1)

A returning user wants to sign in to their existing account. They enter their email and password on a simple sign-in form. Upon successful authentication, they are taken to their dashboard.

**Why this priority**: Equally critical as sign-up; existing users must be able to access their accounts. Tied for P1 as both are needed for a usable MVP.

**Independent Test**: Can be fully tested by creating a user, then signing in with those credentials and verifying access is granted.

**Acceptance Scenarios**:

1. **Given** a user with an existing account on the sign-in page, **When** they enter valid email and password, **Then** they are authenticated and redirected to the application.
2. **Given** a user on the sign-in page, **When** they enter incorrect credentials, **Then** a security-aware error is shown (e.g., "Invalid email or password" without specifying which is wrong).
3. **Given** a user on the sign-in page, **When** they fail to sign in 5 times consecutively, **Then** the account is temporarily locked for 15 minutes and a clear message explains when they can try again.
4. **Given** a user whose account is temporarily locked due to failed attempts, **When** the lockout period expires, **Then** they can attempt to sign in again normally.
5. **Given** a user on the sign-in page, **When** they want to create a new account instead, **Then** a clear link navigates them to the sign-up page.
6. **Given** a user on the sign-in page, **When** they have forgotten their password, **Then** a clear link navigates them to the password reset flow.

---

### User Story 3 - Password Reset (Priority: P2)

A user who has forgotten their password needs to regain access. They request a password reset by entering their email. They receive an email with a secure, time-limited link. Clicking the link takes them to a form where they set a new password.

**Why this priority**: Critical for user retention. Without password reset, locked-out users cannot return, but it depends on sign-in existing first.

**Independent Test**: Can be tested by requesting a reset for an existing user, clicking the emailed link, and setting a new password, then signing in with the new password.

**Acceptance Scenarios**:

1. **Given** a user on the password reset page, **When** they enter a registered email address, **Then** a password reset email is sent and a confirmation message is shown.
2. **Given** a user on the password reset page, **When** they enter an email that does not exist, **Then** the same confirmation message is shown (no information leakage about account existence).
3. **Given** a user with a valid reset link, **When** they click the link within the expiry period, **Then** they see a form to enter and confirm a new password.
4. **Given** a user with an expired or already-used reset link, **When** they click the link, **Then** they see a clear message that the link is no longer valid and can request a new one.
5. **Given** a user setting a new password via reset, **When** they submit a valid new password, **Then** the password is updated and they are redirected to sign in.

---

### User Story 4 - Third-Party OAuth Sign In/Sign Up (Priority: P2)

A user prefers to sign in or sign up using their existing account from a third-party provider (Google, Facebook, Apple, etc.). They click the provider button, authorize access, and are signed in or have a new account created automatically.

**Why this priority**: Reduces friction significantly for users who prefer not to create separate credentials. Important for adoption but not strictly required for MVP.

**Independent Test**: Can be tested by clicking an OAuth provider button, completing the provider authorization flow, and verifying the user is signed in with a linked account.

**Acceptance Scenarios**:

1. **Given** a visitor on the sign-in or sign-up page, **When** they click a third-party provider button (e.g., Google), **Then** they are redirected to the provider's authorization page.
2. **Given** a user completing OAuth authorization for the first time, **When** the provider returns successfully, **Then** they are shown a brief screen to accept TOS/PP before their account is created and they are signed in.
3. **Given** a user with an existing OAuth-linked account, **When** they sign in via the same provider, **Then** they are authenticated and signed in to their existing account.
4. **Given** a user with an existing email/password account, **When** they sign in via an OAuth provider using the same email, **Then** they are prompted to enter their existing account password to confirm the link before the OAuth identity is associated.
5. **Given** a user prompted to confirm OAuth linking, **When** they enter the correct existing account password, **Then** the OAuth identity is linked and they are signed in.
6. **Given** a user prompted to confirm OAuth linking, **When** they enter an incorrect password or cancel, **Then** the link is not created and a clear message explains they can try again or sign in with their existing credentials.
7. **Given** a user completing OAuth authorization, **When** the provider returns an error or the user cancels, **Then** a clear error message is shown and the user can try again.

---

### User Story 5 - Two-Factor Authentication Setup (Priority: P3)

A user with an email/password account wants to add an extra layer of security by enabling two-factor authentication. They navigate to their security settings, enable 2FA, scan a QR code with their authenticator app, and confirm with a verification code.

**Why this priority**: Enhances security posture but is optional for users. Can be implemented after core authentication flows are stable.

**Independent Test**: Can be tested by enabling 2FA for an account, signing out, and verifying that sign-in now requires both password and a TOTP code.

**Acceptance Scenarios**:

1. **Given** a signed-in user in security settings, **When** they choose to enable 2FA, **Then** they are shown a QR code and a text-based secret key for their authenticator app.
2. **Given** a user setting up 2FA, **When** they enter a valid verification code from their authenticator app, **Then** 2FA is enabled and backup/recovery codes are displayed for safekeeping.
3. **Given** a user with 2FA enabled on the sign-in page, **When** they enter correct email and password, **Then** they are prompted for their 2FA code before being granted access.
4. **Given** a user with 2FA who has lost their authenticator, **When** they use a valid backup/recovery code, **Then** they are granted access and that recovery code is invalidated.
5. **Given** a signed-in user with 2FA enabled, **When** they choose to disable 2FA, **Then** they must confirm with their current password and a 2FA code before it is disabled.

---

### Edge Cases

- What happens when a user tries to sign up with an email address using different casing (e.g., "User@Email.com" vs "user@email.com")? Email comparison MUST be case-insensitive.
- What happens when a user submits the sign-up or sign-in form multiple times rapidly? The system MUST prevent duplicate account creation and handle concurrent submissions gracefully.
- What happens when a third-party OAuth provider is temporarily unavailable? The system MUST show a clear error and suggest alternative sign-in methods.
- What happens when a user's session expires? The system MUST redirect them to the sign-in page with a friendly message.
- What happens when a user requests multiple password resets? Only the most recent reset link MUST be valid; previous links MUST be invalidated.
- What happens if a user with 2FA enabled loses both their authenticator and backup codes? The system MUST provide an account recovery path (e.g., contacting support).
- What happens when a user is temporarily locked out due to failed sign-in attempts? The system MUST show how much time remains before they can try again and MUST NOT reset the lockout timer on additional failed attempts during the lockout period.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow new users to create accounts with name, email address, password, and password confirmation.
- **FR-002**: System MUST require acceptance of Terms of Service and Privacy Policy before account creation, for both email/password sign-up (on the sign-up form) and OAuth sign-up (on a brief acceptance screen after provider return).
- **FR-003**: System MUST enforce email uniqueness using case-insensitive comparison.
- **FR-004**: System MUST enforce a password policy requiring: minimum 8 characters, at least one uppercase letter, one lowercase letter, one number, and one special character.
- **FR-005**: System MUST validate that password and password confirmation match before account creation.
- **FR-006**: System MUST allow existing users to sign in with email and password.
- **FR-007**: System MUST provide a password reset workflow via email with time-limited, single-use reset tokens.
- **FR-008**: System MUST support third-party OAuth authentication via Google, Facebook, and Apple at minimum.
- **FR-009**: System MUST support optional two-factor authentication using TOTP (Time-based One-Time Password) for email/password accounts.
- **FR-010**: System MUST generate and display backup/recovery codes when 2FA is enabled.
- **FR-011**: System MUST display clear, visible error messages for all form validation failures.
- **FR-012**: System MUST use security-aware error messages that do not leak information about account existence (e.g., sign-in errors MUST NOT distinguish between "email not found" and "wrong password").
- **FR-013**: System MUST link OAuth identities to existing accounts when the email address matches, but ONLY after the user confirms ownership by entering their existing account password.
- **FR-014**: System MUST invalidate previous password reset tokens when a new reset is requested.
- **FR-015**: System MUST allow users to enable and disable 2FA from their security settings, requiring current credentials for both actions.
- **FR-016**: System MUST send a verification email upon account creation for email/password sign-ups.
- **FR-017**: System MUST grant full application access during a 24-hour grace period after sign-up, showing a persistent non-blocking verification reminder.
- **FR-018**: System MUST lock unverified accounts after the 24-hour grace period until email verification is completed, with an option to resend the verification email.
- **FR-019**: System MUST temporarily lock an account for 15 minutes after 5 consecutive failed sign-in attempts, with escalating lockout duration on repeated lockouts.
- **FR-020**: System MUST display a clear, friendly message indicating the lockout duration when an account is temporarily locked due to failed attempts.

### Key Entities

- **User**: Represents an authenticated individual. Key attributes: name, email (unique, case-insensitive), encrypted password, TOS/PP acceptance timestamp, 2FA enabled status, email verified status, email verification grace period expiry.
- **OAuth Identity**: Represents a link between a User and a third-party provider. Key attributes: provider name, provider user identifier, associated User. A User may have multiple OAuth Identities.
- **Password Reset Token**: Represents a time-limited, single-use token for password recovery. Key attributes: token value, associated User, expiration time, used status.
- **Two-Factor Credential**: Represents TOTP configuration for a User. Key attributes: encrypted secret key, associated User, enabled status.
- **Recovery Code**: Represents a one-time-use backup code for 2FA recovery. Key attributes: encrypted code value, associated User, used status.

### Assumptions

- Password reset tokens expire after 2 hours (industry standard).
- Recovery codes are generated as a set of 10 single-use codes.
- OAuth provider configuration (client IDs, secrets) will be managed via environment/credentials.
- Terms of Service and Privacy Policy content pages exist but are outside the scope of this feature (only the acceptance checkbox is in scope).
- Email delivery for password resets is handled by the application's existing or planned email infrastructure.
- Session management (duration, remember-me, logout) follows standard web application conventions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete account creation in under 60 seconds.
- **SC-002**: Users can sign in to an existing account in under 10 seconds.
- **SC-003**: 95% of users successfully complete the sign-up process on their first attempt without encountering unclear errors.
- **SC-004**: Password reset emails are delivered within 2 minutes of the request.
- **SC-005**: Users can complete the OAuth sign-in flow (from clicking the provider button to being signed in) in under 15 seconds.
- **SC-006**: All error messages are visible without scrolling and use clear, non-technical language.
- **SC-007**: All authentication pages are fully functional on mobile devices (phones and tablets) as well as desktop screens.
- **SC-008**: Two-factor authentication setup can be completed in under 3 minutes.
