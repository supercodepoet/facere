# Quickstart: User Authentication

**Branch**: `001-user-auth` | **Date**: 2026-03-05

## Prerequisites

- Ruby 4.0.1 (per `.ruby-version`)
- Rails 8.1.2
- SQLite 3.x
- Node.js (for Selenium system tests)
- Chrome/Chromium (for system tests)

## Setup

### 1. Install dependencies

```bash
bundle install
```

### 2. Generate Rails authentication scaffold

```bash
bin/rails generate authentication
```

This creates the base User model, Session model, SessionsController,
PasswordsController, and Authentication concern.

### 3. Run migrations

```bash
bin/rails db:migrate
```

### 4. Configure OAuth providers

Add OAuth credentials to Rails credentials:

```bash
bin/rails credentials:edit
```

Add the following structure:

```yaml
omniauth:
  google:
    client_id: YOUR_GOOGLE_CLIENT_ID
    client_secret: YOUR_GOOGLE_CLIENT_SECRET
  facebook:
    app_id: YOUR_FACEBOOK_APP_ID
    app_secret: YOUR_FACEBOOK_APP_SECRET
  apple:
    client_id: YOUR_APPLE_CLIENT_ID
    team_id: YOUR_APPLE_TEAM_ID
    key_id: YOUR_APPLE_KEY_ID
    private_key: YOUR_APPLE_PRIVATE_KEY
```

### 5. Configure Font Awesome Pro

Add CDN kit script tag to `app/views/layouts/application.html.erb`:

```html
<!-- In <head> section -->
<script src="https://kit.fontawesome.com/YOUR_KIT_ID.js"></script>
```

### 6. Start the development server

```bash
bin/dev
```

## Verification

### Sign Up Flow

1. Visit `http://localhost:3000/sign_up`
2. Fill in name, email, password, confirm password
3. Accept TOS/PP checkbox
4. Submit form
5. Verify: account created, signed in, verification email sent

### Sign In Flow

1. Visit `http://localhost:3000/sign_in`
2. Enter email and password
3. Submit form
4. Verify: authenticated and redirected

### Password Reset Flow

1. Visit `http://localhost:3000/sign_in`
2. Click "Forgot password?"
3. Enter email address
4. Check email for reset link
5. Click link, set new password
6. Verify: can sign in with new password

### OAuth Flow

1. Visit `http://localhost:3000/sign_in`
2. Click a provider button (Google/Facebook/Apple)
3. Complete provider authorization
4. If new user: accept TOS/PP on interstitial screen
5. Verify: signed in with linked account

### 2FA Flow

1. Sign in to an account
2. Navigate to security settings
3. Click "Enable Two-Factor Authentication"
4. Scan QR code with authenticator app
5. Enter verification code
6. Save recovery codes
7. Sign out and sign back in
8. Verify: prompted for 2FA code after password

## Running Tests

```bash
# All tests
bin/rails test

# Model tests only
bin/rails test test/models/

# Controller tests only
bin/rails test test/controllers/

# System tests (requires Chrome)
bin/rails test:system

# Specific test file
bin/rails test test/models/user_test.rb
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `config/initializers/omniauth.rb` | OAuth provider configuration |
| `config/routes.rb` | Authentication routes |
| `config/credentials.yml.enc` | OAuth secrets (encrypted) |
| `app/views/layouts/authentication.html.erb` | Auth page layout |

## Common Development Tasks

### Add a new OAuth provider

1. Add the provider's strategy gem to `Gemfile`
2. Add credentials via `bin/rails credentials:edit`
3. Add provider config in `config/initializers/omniauth.rb`
4. Add provider button in `app/views/shared/_oauth_buttons.html.erb`

### Modify password policy

Edit validations in `app/models/user.rb` and update the
`form_validation_controller.js` for client-side feedback.

### Adjust lockout thresholds

Edit constants in `app/models/user.rb`:
- `MAX_FAILED_ATTEMPTS` (default: 5)
- `LOCKOUT_DURATION` (default: 15.minutes)
- `LOCKOUT_ESCALATION_FACTOR` (default: 2)
