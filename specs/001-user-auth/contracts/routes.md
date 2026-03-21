# Route Contracts: User Authentication

**Branch**: `001-user-auth` | **Date**: 2026-03-05

## Authentication Routes

All routes serve HTML via Turbo. No JSON API endpoints.

### Registration (Sign Up)

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| GET | `/sign_up` | `registrations#new` | Show sign-up form |
| POST | `/sign_up` | `registrations#create` | Create new account |

### Sessions (Sign In / Out)

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| GET | `/sign_in` | `sessions#new` | Show sign-in form |
| POST | `/sign_in` | `sessions#create` | Authenticate user |
| DELETE | `/sign_out` | `sessions#destroy` | End session |

### Password Reset

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| GET | `/passwords/new` | `passwords#new` | Show reset request form |
| POST | `/passwords` | `passwords#create` | Send reset email |
| GET | `/passwords/:token/edit` | `passwords#edit` | Show new password form |
| PATCH | `/passwords/:token` | `passwords#update` | Set new password |

### Email Verification

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| GET | `/email_verification` | `email_verifications#show` | Verify email via token (query param) |
| POST | `/email_verification` | `email_verifications#create` | Resend verification email |

### OAuth

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| POST | `/auth/:provider` | (OmniAuth middleware) | Initiate OAuth flow |
| GET | `/auth/:provider/callback` | `oauth_callbacks#create` | Handle provider callback |
| GET | `/auth/failure` | `oauth_callbacks#failure` | Handle OAuth failure |
| GET | `/auth/terms` | `oauth_callbacks#terms_acceptance` | Show TOS/PP acceptance for new OAuth users |
| POST | `/auth/terms` | `oauth_callbacks#accept_terms` | Accept TOS/PP and complete account |
| GET | `/auth/link` | `oauth_callbacks#link_account` | Show password confirmation for account linking |
| POST | `/auth/link` | `oauth_callbacks#confirm_link` | Confirm account link with password |

### Two-Factor Authentication

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| GET | `/two_factor/new` | `two_factor_authentication#new` | Show 2FA setup (QR code) |
| POST | `/two_factor` | `two_factor_authentication#create` | Enable 2FA after code verification |
| DELETE | `/two_factor` | `two_factor_authentication#destroy` | Disable 2FA |
| GET | `/two_factor/verify` | `two_factor_authentication#verify` | Show 2FA code entry during sign-in |
| POST | `/two_factor/verify` | `two_factor_authentication#confirm` | Verify 2FA code during sign-in |
| GET | `/two_factor/recovery_codes` | `two_factor_authentication#recovery_codes` | Display recovery codes |

## Route Naming Conventions

- Named routes follow Rails conventions (e.g., `sign_in_path`,
  `sign_up_path`, `new_password_path`)
- OAuth routes use `/auth` prefix (OmniAuth convention)
- All routes are within the default namespace (no API versioning needed)

## Authentication Requirements

| Route Group | Requires Auth | Notes |
|-------------|--------------|-------|
| Registration | No | Public access |
| Sessions (new, create) | No | Public access |
| Sessions (destroy) | Yes | Must be signed in |
| Password Reset | No | Public access (token-based) |
| Email Verification | No | Public access (token-based) |
| OAuth (initiate, callback) | No | Public access |
| OAuth (terms, link) | No | Session-stored temp data |
| 2FA (new, create, destroy) | Yes | Must be signed in |
| 2FA (verify, confirm) | Partial | After password auth, before full session |
| 2FA (recovery_codes) | Yes | Must be signed in |
