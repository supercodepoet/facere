# Research: User Authentication

**Branch**: `001-user-auth` | **Date**: 2026-03-05

## R1: Rails 8.1 Built-in Authentication

**Decision**: Use `rails generate authentication` as the foundation for
email/password authentication, then extend for additional requirements.

**Rationale**: Rails 8 introduced a built-in authentication generator
(`bin/rails generate authentication`) that scaffolds a complete,
production-ready authentication system. It generates:

- `User` model with `has_secure_password` (bcrypt-based)
- `Session` model for database-backed sessions
- `SessionsController` for sign-in/sign-out
- `PasswordsController` for password reset flow
- `Authentication` concern for controllers
- Mailer for password reset emails
- Database migrations for users and sessions tables
- Basic views for sign-in and password reset forms

This aligns perfectly with Constitution Principle I (Vanilla Rails First)
and Principle II (Library-First - use what Rails provides before gems).

**Alternatives considered**:
- **Devise**: Full-featured but adds significant complexity; violates
  Principle VII (Simplicity) and Principle I (Vanilla Rails First)
- **Clearance**: Lighter than Devise but still an external dependency
  when Rails provides the core functionality
- **Custom from scratch**: Violates Principle II (Library-First)

**Extension needed**: The generator does not include email verification,
account lockout, OAuth, or 2FA. These will be added as extensions to
the generated foundation.

## R2: Password Hashing (bcrypt / has_secure_password)

**Decision**: Use `has_secure_password` with bcrypt gem (already in
Gemfile, commented out - uncomment it).

**Rationale**: `has_secure_password` provides:
- Secure bcrypt password hashing with configurable cost
- `password` and `password_confirmation` virtual attributes
- `authenticate` method for credential verification
- Automatic presence validation on password
- Built into Active Model; no additional gems beyond bcrypt

This is the Rails-standard approach and what the authentication
generator uses.

## R3: OAuth via OmniAuth

**Decision**: Use the `omniauth` gem with provider-specific strategy
gems (`omniauth-google-oauth2`, `omniauth-facebook`,
`omniauth-apple`).

**Rationale**: OmniAuth is the de facto standard for OAuth in Rails.
It provides a Rack middleware with a consistent callback interface
regardless of provider. Each provider is a "strategy" gem.

Required gems:
- `omniauth` (core)
- `omniauth-rails_csrf_protection` (CSRF protection for OmniAuth)
- `omniauth-google-oauth2` (Google provider)
- `omniauth-facebook` (Facebook provider)
- `omniauth-apple` (Apple Sign In)

**Alternatives considered**:
- **Custom OAuth implementation**: Violates Principle II (Library-First);
  OAuth is complex with many edge cases
- **Doorkeeper**: Server-side OAuth provider, not consumer
- **Rodauth**: Full auth framework but would conflict with Rails
  authentication generator approach

## R4: Two-Factor Authentication (TOTP)

**Decision**: Use the `rotp` gem for TOTP generation/verification and
`rqrcode` for QR code generation.

**Rationale**:
- `rotp` is a lightweight, well-maintained gem implementing RFC 6238
  (TOTP) and RFC 4226 (HOTP). It handles secret generation, OTP
  verification with time-drift tolerance, and provisioning URIs.
- `rqrcode` generates QR codes that can be rendered as SVG or PNG
  for authenticator app setup.
- Both are small, focused libraries (Principle VII - Simplicity).

Required gems:
- `rotp` (TOTP generation and verification)
- `rqrcode` (QR code generation for authenticator app enrollment)

**Alternatives considered**:
- **devise-two-factor**: Tightly coupled to Devise; not applicable
- **two_factor_authentication**: Also Devise-dependent
- **Custom TOTP implementation**: TOTP is standardized; using a
  well-tested gem is safer (Principle II)

## R5: Email Verification

**Decision**: Build custom email verification using Rails built-in
signed tokens (`generates_token_for`) and Action Mailer.

**Rationale**: Rails 7.1+ provides `generates_token_for` which creates
secure, signed, expiring tokens without needing a separate database
table. This is ideal for email verification tokens. Combined with
Action Mailer, this provides a complete email verification flow using
only Rails built-in tools.

Pattern:
```ruby
class User < ApplicationRecord
  generates_token_for :email_verification, expires_in: 24.hours do
    email
  end
end
```

This aligns with Principle I (Vanilla Rails First).

## R6: Account Lockout / Rate Limiting

**Decision**: Use Rails 8's built-in `rate_limit` controller macro
for rate limiting, plus a custom `failed_login_attempts` counter on
the User model for account lockout.

**Rationale**: Rails 8 introduced `rate_limit` as a controller-level
macro that provides built-in request throttling using the cache store.
For account-specific lockout (5 attempts, 15-minute escalating
lockout), we track `failed_login_attempts` and `locked_until` on the
User model.

```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: :create
end
```

**Alternatives considered**:
- **Rack::Attack**: More powerful but adds an external dependency;
  Rails 8's built-in rate limiting covers the primary use case
- **Custom Rack middleware**: Unnecessary complexity

## R7: Web Awesome Pro Integration

**Decision**: Load Web Awesome Pro via CDN kit script tag in the
application layout. Use Web Awesome web components (`<wa-input>`,
`<wa-button>`, `<wa-checkbox>`, `<wa-callout>`, `<wa-card>`,
`<wa-dialog>`, etc.) for all UI elements.

**Rationale**: Web Awesome Pro provides a comprehensive web component
library with built-in theming, animations, and responsive design.
Components are standard Web Components that emit native DOM events,
making them compatible with Stimulus controllers.

Key integration points:
- Web Awesome components use standard form participation (they work
  with `<form>` elements natively via `FormData`)
- Events like `wa-input`, `wa-change`, `wa-submit` can be listened
  to via Stimulus `data-action` attributes
- Theming via CSS custom properties allows global theme control
- Components are responsive by default

**Font Awesome Pro**: Loaded via CDN kit script tag alongside Web
Awesome Pro. Used for all iconography via `<i class="fa-solid fa-*">`
or the `<wa-icon>` web component.

## R8: Stimulus Controllers for Authentication

**Decision**: Create focused Stimulus controllers for each
authentication interaction pattern.

**Rationale**: Per Constitution Principle VI (Separation of Concerns),
Stimulus controllers handle DOM interaction while Turbo handles
server communication. Authentication-specific controllers:

- `form_validation_controller`: Real-time client-side validation
  (password strength, email format, confirmation match)
- `password_visibility_controller`: Toggle password field visibility
- `oauth_controller`: Handle OAuth button interactions and loading
  states
- `two_factor_controller`: QR code display, code input formatting,
  recovery code display/copy

Server-side form submission uses standard Turbo form submission
(Turbo Drive intercepts `<form>` submissions automatically).

## R9: Mailer Strategy

**Decision**: Use Action Mailer with the existing Rails mailer
infrastructure for all authentication emails (password reset,
email verification).

**Rationale**: The Rails authentication generator already scaffolds
a `PasswordsMailer`. We extend this pattern with an additional
`UserMailer` or `EmailVerificationMailer` for verification emails.
Solid Queue (already in Gemfile) handles async delivery via
Active Job.

## R10: Session Management

**Decision**: Use the database-backed session model from the Rails
authentication generator, stored in SQLite.

**Rationale**: The Rails authentication generator creates a `Session`
model that tracks active sessions. This provides:
- Multiple device session tracking
- Session revocation capability
- User-agent and IP recording for security
- Foundation for "remember me" functionality

Uses Solid Cache (already in Gemfile) for session-related caching.
