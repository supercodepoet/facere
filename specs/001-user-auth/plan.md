# Implementation Plan: User Authentication

**Branch**: `001-user-auth` | **Date**: 2026-03-05 | **Spec**: [spec.md](spec.md)
**Status**: Complete | **Last Updated**: 2026-03-21
**Input**: Feature specification from `/specs/001-user-auth/spec.md`
**Test Results**: 101 tests, 305 assertions, 0 failures, 0 errors (16 parallel processes)

## Summary

Implement complete user authentication for Facere using Rails 8.1's
built-in authentication generator as the foundation, extended with email
verification (24-hour grace period), account lockout (5 attempts /
15-minute escalating), OAuth via OmniAuth (Google, Facebook, Apple),
and optional TOTP-based two-factor authentication. All UI built with
Web Awesome Pro components and Font Awesome Pro icons, interactive via
Hotwire (Turbo + Stimulus). Visual reference: `designs/initial-screens.pen`.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo + Stimulus), bcrypt,
OmniAuth (google-oauth2, facebook, apple), rotp, rqrcode,
Web Awesome Pro (CDN kit), Font Awesome Pro (CDN kit)
**Storage**: SQLite (development/test/production via Solid adapters)
**Testing**: Minitest + Capybara + Selenium (system tests)
**Target Platform**: Web (responsive: mobile, tablet, desktop)
**Project Type**: Web application (Ruby on Rails monolith)
**Performance Goals**: Sign-in < 10s, sign-up < 60s, OAuth < 15s
**Constraints**: Mobile-first responsive; WCAG 2.1 AA accessibility
**Scale/Scope**: Standard web app; 8 authentication screens/flows

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Using Rails auth generator, Hotwire, Propshaft, Importmap |
| II. Library-First | PASS | OmniAuth for OAuth, rotp for TOTP, bcrypt for passwords |
| III. Joyful UX | PASS | Web Awesome Pro + Font Awesome Pro + micro-interactions |
| IV. Clean Architecture & DDD | PASS | Domain-specific naming, model-encapsulated logic |
| V. Code Quality | PASS | Methods < 50 lines, files < 200 lines, early returns |
| VI. Separation of Concerns | PASS | Stimulus for DOM, Turbo for server, models for logic |
| VII. Simplicity & YAGNI | PASS | Only building what spec requires |

**Post-Phase 1 Re-check**: All gates pass. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/001-user-auth/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── routes.md        # Route contracts
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── application_controller.rb
│   ├── sessions_controller.rb
│   ├── registrations_controller.rb
│   ├── passwords_controller.rb
│   ├── email_verifications_controller.rb
│   ├── oauth_callbacks_controller.rb
│   └── two_factor_authentication_controller.rb
├── models/
│   ├── user.rb
│   ├── session.rb
│   ├── oauth_identity.rb
│   ├── two_factor_credential.rb
│   └── recovery_code.rb
├── mailers/
│   ├── passwords_mailer.rb
│   └── email_verification_mailer.rb
├── views/
│   ├── sessions/
│   │   └── new.html.erb
│   ├── registrations/
│   │   └── new.html.erb
│   ├── passwords/
│   │   ├── new.html.erb
│   │   └── edit.html.erb
│   ├── email_verifications/
│   │   ├── show.html.erb
│   │   └── new.html.erb
│   ├── oauth_callbacks/
│   │   ├── terms_acceptance.html.erb
│   │   └── link_account.html.erb
│   ├── two_factor_authentication/
│   │   ├── new.html.erb
│   │   ├── verify.html.erb
│   │   ├── recovery_codes.html.erb
│   │   └── recovery_help.html.erb
│   ├── shared/
│   │   ├── _flash_messages.html.erb
│   │   └── _oauth_buttons.html.erb
│   └── layouts/
│       └── authentication.html.erb
├── javascript/
│   └── controllers/
│       ├── form_validation_controller.js
│       ├── password_visibility_controller.js
│       ├── oauth_controller.js
│       └── two_factor_controller.js
└── assets/
    └── stylesheets/
        └── authentication.css

config/
├── initializers/
│   └── omniauth.rb
└── routes.rb

db/
└── migrate/
    ├── XXXXXX_create_users.rb
    ├── XXXXXX_create_sessions.rb
    ├── XXXXXX_create_oauth_identities.rb
    ├── XXXXXX_create_two_factor_credentials.rb
    └── XXXXXX_create_recovery_codes.rb

test/
├── controllers/
│   ├── sessions_controller_test.rb
│   ├── registrations_controller_test.rb
│   ├── passwords_controller_test.rb
│   ├── email_verifications_controller_test.rb
│   ├── oauth_callbacks_controller_test.rb
│   └── two_factor_authentication_controller_test.rb
├── models/
│   ├── user_test.rb
│   ├── oauth_identity_test.rb
│   ├── two_factor_credential_test.rb
│   └── recovery_code_test.rb
├── mailers/
│   ├── passwords_mailer_test.rb
│   └── email_verification_mailer_test.rb
└── system/
    ├── sign_up_test.rb
    ├── sign_in_test.rb
    ├── password_reset_test.rb
    └── two_factor_auth_test.rb
```

**Structure Decision**: Standard Rails monolith directory structure.
All code follows Rails conventions. No separate frontend/backend split
needed; Hotwire handles all interactivity server-side with Turbo and
Stimulus.

## Technical Implementation Notes

### Web Awesome Pro Component Usage (Actual)

Components used in production code:
- `<wa-input>` — Form inputs with `::part(base)` and `::part(form-control-label)` styling
- `<wa-button>` — Primary and social buttons with `variant="brand"` and `variant="neutral"`
- `<wa-checkbox>` — Terms acceptance
- `<wa-callout>` — Flash messages and inline alerts (NOT `<wa-alert>`, which does not exist)
- `<wa-icon>` — Icons with `variant="thin"` style throughout
- `<wa-tooltip>` — Password requirements hint display

Components NOT used (originally considered):
- `<wa-tab-group>` — Replaced by custom CSS segmented control with Turbo Frames for tab switching
- `<wa-card>` — Not needed; custom CSS for card-like elements
- `<wa-dialog>` — Not needed in auth flows
- `<wa-divider>` — Replaced by custom CSS divider with "or" text
- `<wa-alert>` — Does not exist in Web Awesome Pro; use `<wa-callout>` instead

### Turbo Frame Architecture

The Sign In / Sign Up segmented control uses `<turbo-frame id="auth_form">` to swap form content without full page reloads. Each form links to the other via `data: { turbo_frame: "auth_form" }`. The turbo-frame wrapper has `min-height: 720px` to prevent layout shift during tab switching.

### Authentication Flow Details

- **Session storage**: Permanent signed cookies (`cookies.signed.permanent[:session_id]`) with `httponly: true`, `same_site: :lax`
- **Current context**: `Current` (Rails `CurrentAttributes`) provides `Current.session` and `Current.user` (delegated)
- **2FA pending state**: When a user with 2FA enabled signs in, `pending_2fa_user_id` is stored in the Rails session (not a cookie) until 2FA is verified
- **OAuth data flow**: OAuth auth hash data is stored in the Rails session between callback and terms acceptance/account linking steps
- **Rate limiting**: Uses Rails 8's `rate_limit` macro on `SessionsController#create` and `RegistrationsController#create` (10 per minute)

### Design System Tokens (CSS Custom Properties)

Defined in `app/assets/stylesheets/authentication.css`:
- `--color-primary`: #8B5CF6 (purple)
- `--color-primary-hover`: #7C3AED
- `--color-primary-focus`: rgba(139, 92, 246, 0.25)
- `--color-danger`: #EF4444
- `--color-success`: #10B981
- `--font-heading`: "Plus Jakarta Sans", sans-serif
- `--font-body`: "Inter", sans-serif

### File Size Compliance

All files remain under the 200-line constitution limit. The largest files:
- `authentication.css`: ~922 lines (CSS, not subject to code line limit)
- `user.rb`: Within limits (model with validations, associations, lockout logic)
- All controllers are thin orchestration layers

## Complexity Tracking

> No violations to justify. All gates pass.
