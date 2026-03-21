# Tasks: User Authentication

**Input**: Design documents from `/specs/001-user-auth/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/routes.md, research.md, quickstart.md
**Visual Reference**: `designs/initial-screens.pen` (Sign In / Sign Up frame, Mobile - Sign In frame)

**Tests**: Included per constitution mandate (Development Workflow & Quality Gates: "All new features MUST include test coverage using Minitest"). Model tests, controller tests, mailer tests, and system tests for each user story.

**Organization**: Tasks grouped by user story (US1-US5) for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Exact file paths included in all descriptions

## UI/UX Reference Notes

**Desktop**: Split layout - branded left panel (#8B5CF6 purple with decorative elements, logo "Facere", tagline, floating task cards) + white auth form panel on right with segmented Sign In / Sign Up toggle.
**Mobile**: Stacked layout - compact brand area on top (rounded bottom corners), form below.
**Fonts**: Plus Jakarta Sans (headings/logo, weight 700-800), Inter (body/labels, weight 400-600).
**Colors**: Primary #8B5CF6, Teal #14B8A6, Pink #F472B6, Amber #F59E0B, Zinc #18181B/#71717A/#A1A1AA.
**Components**: Web Awesome Pro (`<wa-input>`, `<wa-button>`, `<wa-checkbox>`, `<wa-callout>`, `<wa-icon>`, `<wa-tooltip>`) + Font Awesome Pro icons via `<wa-icon>`. Note: `<wa-alert>` does not exist in Web Awesome Pro — use `<wa-callout>` instead. Tab switching uses custom CSS segmented control with Turbo Frames rather than `<wa-tab-group>`.
**Kit**: `<script src="https://kit.webawesome.com/a7eedeb8ff694353.js" crossorigin="anonymous"></script>`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, dependencies, and shared configuration

- [x] T001 Add authentication gems to Gemfile: uncomment `bcrypt`, add `omniauth`, `omniauth-rails_csrf_protection`, `omniauth-google-oauth2`, `omniauth-facebook`, `omniauth-apple`, `rotp`, `rqrcode` in Gemfile
- [x] T002 Run `bundle install` to install all new gem dependencies
- [x] T003 Run `bin/rails generate authentication` to scaffold base User model, Session model, SessionsController, PasswordsController, Authentication concern, and migrations
- [x] T004 Add Web Awesome Pro kit script tag to `app/views/layouts/application.html.erb` in the `<head>` section: `<script src="https://kit.webawesome.com/a7eedeb8ff694353.js" crossorigin="anonymous"></script>`
- [x] T005 Create authentication layout at `app/views/layouts/authentication.html.erb` with the split desktop layout (branded left panel + form right) and stacked mobile layout matching the .pen design. Include Web Awesome Pro kit, Plus Jakarta Sans + Inter font imports, and responsive breakpoints
- [x] T006 Create authentication stylesheet at `app/assets/stylesheets/authentication.css` with CSS custom properties for the design system colors (#8B5CF6 primary, #14B8A6 teal, #F472B6 pink, #F59E0B amber, zinc scale), branded panel styles (decorative circles, floating cards, logo), form panel styles, and responsive mobile layout (stacked, rounded brand area)
- [x] T007 [P] Create flash messages partial at `app/views/shared/_flash_messages.html.erb` using `<wa-callout>` components with appropriate variants (success, warning, danger) and dismissible behavior
- [x] T008 [P] Create OAuth buttons partial at `app/views/shared/_oauth_buttons.html.erb` with Google, Facebook, and Apple sign-in buttons using `<wa-button>` with Font Awesome brand icons (`fa-brands fa-google`, `fa-brands fa-facebook`, `fa-brands fa-apple`), styled to match the .pen social buttons (white fill, #D4D4D8 border, rounded-full)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema, models, and core infrastructure that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T009 Extend the generated User migration to add fields: `name:string` (NOT NULL), `terms_accepted_at:datetime`, `email_verified_at:datetime`, `email_verification_grace_expires_at:datetime`, `failed_login_attempts:integer` (default: 0, NOT NULL), `lockout_count:integer` (default: 0, NOT NULL), `locked_until:datetime` in `db/migrate/XXXXXX_create_users.rb`
- [x] T010 Create OAuthIdentity migration at `db/migrate/` with fields: `user_id:integer` (NOT NULL, FK), `provider:string` (NOT NULL), `uid:string` (NOT NULL), timestamps; add unique index on `[provider, uid]` and index on `user_id`
- [x] T011 [P] Create TwoFactorCredential migration at `db/migrate/` with fields: `user_id:integer` (NOT NULL, FK, UNIQUE), `otp_secret:string` (NOT NULL), `enabled:boolean` (default: false, NOT NULL), timestamps; add unique index on `user_id`
- [x] T012 [P] Create RecoveryCode migration at `db/migrate/` with fields: `user_id:integer` (NOT NULL, FK), `code_digest:string` (NOT NULL), `used_at:datetime`, timestamps; add index on `user_id`
- [x] T013 Run `bin/rails db:migrate` to apply all migrations
- [x] T014 Extend the generated User model in `app/models/user.rb` with: `has_secure_password`, validations (name presence/max 255, email_address presence/uniqueness case-insensitive/format, password complexity on create conditional on `password_required?` private method that returns true only when `password_digest.blank? && oauth_identities.empty?`, terms_accepted_at presence on create), `generates_token_for :email_verification` (24h, scoped to email), `generates_token_for :password_reset` (2h, scoped to password_digest), normalize email to lowercase, associations (`has_many :sessions`, `has_many :oauth_identities`, `has_one :two_factor_credential`, `has_many :recovery_codes`), read-only query methods (`email_verified?`, `within_verification_grace_period?`, `two_factor_enabled?`), lockout constants (MAX_FAILED_ATTEMPTS=5, LOCKOUT_DURATION=15.minutes, LOCKOUT_ESCALATION_FACTOR=2). NOTE: Lockout methods (`locked?`, `lock_account!`, `increment_failed_login_attempts!`, `reset_failed_login_attempts!`) are implemented in T032
- [x] T015 [P] Create OAuthIdentity model at `app/models/oauth_identity.rb` with: `belongs_to :user`, validations (provider presence/inclusion, uid presence/uniqueness scoped to provider)
- [x] T016 [P] Create TwoFactorCredential model at `app/models/two_factor_credential.rb` with: `belongs_to :user`, `encrypts :otp_secret`, validations (otp_secret presence, user_id uniqueness), methods (`provisioning_uri(account_name)` using rotp, `verify_code(code)` with drift tolerance)
- [x] T017 [P] Create RecoveryCode model at `app/models/recovery_code.rb` with: `belongs_to :user`, validations (code_digest presence), methods (`used?`, `consume!`), class method `generate_for(user, count: 10)` that generates plaintext codes, stores bcrypt digests, returns plaintext array
- [x] T018 Configure authentication routes in `config/routes.rb` per contracts/routes.md: registration (GET/POST /sign_up), sessions (GET/POST /sign_in, DELETE /sign_out), passwords (GET/POST /passwords/new, GET/PATCH /passwords/:token), email verification (GET/POST /email_verification), OAuth (/auth/:provider, /auth/:provider/callback, /auth/failure, /auth/terms, /auth/link), 2FA (/two_factor/*)
- [x] T019 [P] Configure OmniAuth initializer at `config/initializers/omniauth.rb` with Google, Facebook, and Apple provider strategies reading credentials from Rails credentials store, plus CSRF protection middleware
- [x] T020 [P] Configure Active Record Encryption for TwoFactorCredential.otp_secret - ensure `config/credentials.yml.enc` has encryption keys (or generate via `bin/rails db:encryption:init`)

**Checkpoint**: Foundation ready - all models, migrations, routes, and configuration in place

---

## Phase 3: User Story 1 - Sign Up with Email and Password (Priority: P1) MVP

**Goal**: New visitors can create accounts with name, email, password, TOS acceptance. Email verification sent with 24h grace period.

**Independent Test**: Navigate to /sign_up, fill form, submit. Verify account created, user signed in, verification email sent.

### Implementation for User Story 1

- [x] T021 [US1] Create RegistrationsController at `app/controllers/registrations_controller.rb` with `new` action (render sign-up form with authentication layout) and `create` action (build User with strong params [name, email_address, password, password_confirmation, terms_accepted_at], set email_verification_grace_expires_at to 24h from now, save, create session, send verification email via EmailVerificationMailer, redirect to root; on failure re-render form with errors)
- [x] T022 [US1] Create sign-up view at `app/views/registrations/new.html.erb` matching the .pen design: use the segmented control (`<wa-tab-group>` or custom segmented with Sign In / Sign Up tabs, Sign Up active), form with `<wa-input>` for name (label "Name", required), email (label "Email", type email, required), password (label "Password", type password, required, with visibility toggle), password confirmation (label "Confirm Password", type password, required), `<wa-checkbox>` for TOS/PP acceptance, `<wa-button>` submit (primary purple #8B5CF6, full width, rounded-full, "Create Account") with `data-turbo-submits-with="Creating account..."` to prevent double-submission, OAuth buttons partial below divider, link to sign-in ("Already have an account? Sign In")
- [x] T023 [US1] Create EmailVerificationMailer at `app/mailers/email_verification_mailer.rb` with `verification_email(user)` method that generates token via `user.generate_token_for(:email_verification)` and sends email with verification link to `/email_verification?token=TOKEN`
- [x] T024 [US1] Create email verification mailer views at `app/views/email_verification_mailer/verification_email.html.erb` and `app/views/email_verification_mailer/verification_email.text.erb` with branded email template containing the verification link and 24h expiry notice
- [x] T025 [US1] Create EmailVerificationsController at `app/controllers/email_verifications_controller.rb` with `show` action (find user by token via `User.find_by_token_for(:email_verification, params[:token])`, set email_verified_at, clear grace expiry, redirect with success flash; handle invalid/expired token with error flash) and `create` action (resend verification email to current user, rate-limit to prevent abuse)
- [x] T026 [US1] Create email verification views at `app/views/email_verifications/show.html.erb` (verification result page) and pending verification prompt view for locked accounts at `app/views/email_verifications/new.html.erb` (shows "verify your email" message with resend button)
- [x] T027 [US1] Create form_validation_controller Stimulus controller at `app/javascript/controllers/form_validation_controller.js` with real-time client-side validation: password strength indicator (min 8 chars, uppercase, lowercase, digit, special char with visual checklist), password confirmation match check, email format validation, TOS checkbox required check; use `wa-input` invalid state and help-text slots for inline feedback
- [x] T028 [US1] Create password_visibility_controller Stimulus controller at `app/javascript/controllers/password_visibility_controller.js` to toggle password field visibility using `<wa-icon-button>` with Font Awesome eye/eye-slash icons (`fa-solid fa-eye` / `fa-solid fa-eye-slash`), toggling the `<wa-input>` type between "password" and "text"
- [x] T029 [US1] Add email verification grace period enforcement to the Authentication concern in `app/controllers/concerns/authentication.rb`: after authenticating the session, check if the user's grace period has expired and email is not verified; if so, redirect to email verification prompt page (`/email_verification` new) instead of the requested page. Show non-blocking verification reminder banner (via `<wa-callout>` variant="warning" in application layout) if within grace period and unverified. Also handle expired/missing sessions: when session lookup returns nil, redirect to sign_in_path with flash notice "Your session has expired. Please sign in again."

### Tests for User Story 1

- [x] T029a [P] [US1] Create User model test at `test/models/user_test.rb`: test validations (name presence, email uniqueness case-insensitive, email format, password complexity via `password_required?`, terms_accepted_at presence on create), test email normalization to lowercase, test `generates_token_for(:email_verification)` token generation and expiry, test `email_verified?` and `within_verification_grace_period?` methods
- [x] T029b [P] [US1] Create RegistrationsController test at `test/controllers/registrations_controller_test.rb`: test GET /sign_up renders form, test POST /sign_up with valid params creates user and session, test POST /sign_up with invalid params re-renders with errors, test duplicate email rejection with security-aware message, test TOS not accepted rejection
- [x] T029c [P] [US1] Create EmailVerificationsController test at `test/controllers/email_verifications_controller_test.rb`: test valid token verifies email and clears grace expiry, test expired/invalid token shows error, test resend action sends new email, test rate limiting on resend
- [x] T029d [P] [US1] Create EmailVerificationMailer test at `test/mailers/email_verification_mailer_test.rb`: test verification email contains correct link with token, test email body includes 24h expiry notice
- [x] T029e [US1] Create sign-up system test at `test/system/sign_up_test.rb`: test full sign-up flow end-to-end with Capybara (navigate to /sign_up, fill name/email/password/confirmation, accept TOS, submit, verify signed in and verification email enqueued)

**Checkpoint**: Sign Up flow fully functional. Users can create accounts, receive verification emails, and are enforced on the 24h grace period.

---

## Phase 4: User Story 2 - Sign In with Email and Password (Priority: P1) MVP

**Goal**: Returning users can sign in with email/password. Account lockout after 5 failed attempts with escalating duration.

**Independent Test**: Create a user, navigate to /sign_in, enter credentials, verify authenticated and redirected.

### Implementation for User Story 2

- [x] T030 [US2] Update the generated SessionsController at `app/controllers/sessions_controller.rb`: `new` action renders sign-in form with authentication layout; `create` action finds user by email (case-insensitive), checks if locked (show lockout message with remaining time), authenticates with password, on success reset_failed_login_attempts and create session and redirect, on failure increment_failed_login_attempts and re-render with security-aware error ("Invalid email or password"); add `rate_limit to: 10, within: 1.minute, only: :create`; `destroy` action ends session and redirects to sign_in
- [x] T031 [US2] Create sign-in view at `app/views/sessions/new.html.erb` matching the .pen design: segmented control (Sign In active / Sign Up tab), form with `<wa-input>` for email (label "Email", type email, required) and password (label "Password", type password, required, with visibility toggle), "Forgot password?" link aligned right below password field (text color #8B5CF6), `<wa-button>` submit (primary purple, full width, rounded-full, "Sign In") with `data-turbo-submits-with="Signing in..."`, divider row ("or" text between lines), OAuth buttons partial, "Don't have an account? Sign Up" prompt at bottom
- [x] T032 [US2] Implement account lockout logic in User model methods in `app/models/user.rb`: `increment_failed_login_attempts!` increments counter, when reaching MAX_FAILED_ATTEMPTS calls `lock_account!` with escalating duration (LOCKOUT_DURATION * LOCKOUT_ESCALATION_FACTOR^lockout_count) and increments `lockout_count`; `locked?` checks if `locked_until` is present and in the future; `lock_account!(duration)` sets `locked_until`; `reset_failed_login_attempts!` resets `failed_login_attempts` to 0, resets `lockout_count` to 0, and clears `locked_until`
- [x] T033 [US2] Add lockout display to sign-in view: when account is locked, show `<wa-callout>` variant="warning" with friendly message including remaining lockout time (e.g., "Account temporarily locked. Try again in X minutes.") using a Stimulus controller or inline ERB calculation

### Tests for User Story 2

- [x] T033a [P] [US2] Create SessionsController test at `test/controllers/sessions_controller_test.rb`: test GET /sign_in renders form, test POST /sign_in with valid credentials creates session and redirects, test POST /sign_in with invalid credentials shows security-aware error ("Invalid email or password"), test account lockout after 5 consecutive failures, test lockout expiry allows retry, test rate limiting (10 requests/minute), test DELETE /sign_out destroys session
- [x] T033b [US2] Create sign-in system test at `test/system/sign_in_test.rb`: test full sign-in flow with Capybara (navigate to /sign_in, enter credentials, submit, verify authenticated), test lockout message display, test navigation links to sign-up and forgot password

**Checkpoint**: Sign In flow fully functional with lockout protection. Combined with US1, users can sign up and sign in (MVP complete).

---

## Phase 5: User Story 3 - Password Reset (Priority: P2)

**Goal**: Users who forgot their password can request a reset email, click a time-limited link, and set a new password.

**Independent Test**: Request reset for existing user, click emailed link, set new password, sign in with new password.

### Implementation for User Story 3

- [x] T034 [US3] Update the generated PasswordsController at `app/controllers/passwords_controller.rb`: `new` action renders reset request form with authentication layout; `create` action finds user by email, sends reset email via PasswordsMailer (always shows same confirmation regardless of email existence for security), invalidates previous tokens by design (generates_token_for is scoped to password_digest); `edit` action finds user by token param, renders new password form (or error if invalid/expired); `update` action finds user by token, updates password, redirects to sign_in with success flash
- [x] T035 [US3] Create password reset request view at `app/views/passwords/new.html.erb` with authentication layout: heading "Reset your password", subtext "Enter your email and we'll send you a reset link", `<wa-input>` for email, `<wa-button>` submit (primary purple, "Send Reset Link") with `data-turbo-submits-with="Sending..."`, "Back to Sign In" link
- [x] T036 [US3] Create new password form view at `app/views/passwords/edit.html.erb` with authentication layout: heading "Set new password", `<wa-input>` for new password (with visibility toggle and strength indicator via form_validation_controller), `<wa-input>` for password confirmation, `<wa-button>` submit (primary purple, "Update Password") with `data-turbo-submits-with="Updating..."`
- [x] T037 [US3] Update PasswordsMailer at `app/mailers/passwords_mailer.rb` to use `generates_token_for(:password_reset)` for token generation, send branded email with reset link to `/passwords/TOKEN/edit` and 2-hour expiry notice
- [x] T038 [US3] Create password reset mailer views at `app/views/passwords_mailer/reset.html.erb` and `app/views/passwords_mailer/reset.text.erb` with branded template containing reset link and expiry information

### Tests for User Story 3

- [x] T038a [P] [US3] Create PasswordsController test at `test/controllers/passwords_controller_test.rb`: test GET /passwords/new renders form, test POST /passwords with existing email sends reset email, test POST /passwords with non-existing email shows same confirmation (no info leakage), test GET /passwords/:token/edit with valid token renders form, test GET /passwords/:token/edit with expired token shows error, test PATCH /passwords/:token updates password and redirects to sign_in
- [x] T038b [P] [US3] Create PasswordsMailer test at `test/mailers/passwords_mailer_test.rb`: test reset email contains correct link with token, test email body includes 2-hour expiry notice
- [x] T038c [US3] Create password reset system test at `test/system/password_reset_test.rb`: test full reset flow end-to-end (request reset, extract token from email, visit link, set new password, sign in with new password)

**Checkpoint**: Password reset flow complete. Users can recover access to their accounts.

---

## Phase 6: User Story 4 - Third-Party OAuth Sign In/Sign Up (Priority: P2)

**Goal**: Users can sign in or sign up via Google, Facebook, or Apple. New OAuth users accept TOS/PP. Existing email matches require password confirmation to link.

**Independent Test**: Click OAuth provider button, complete authorization, verify signed in with linked account.

### Implementation for User Story 4

- [x] T039 [US4] Create OAuthCallbacksController at `app/controllers/oauth_callbacks_controller.rb` with: `create` action (handle provider callback from OmniAuth - extract auth hash, find existing OAuthIdentity or find User by email; if existing OAuth identity: sign in directly; if user exists with same email but no OAuth link: store auth data in session, redirect to /auth/link for password confirmation; if new user: store auth data in session, redirect to /auth/terms for TOS acceptance) and `failure` action (flash error, redirect to sign_in)
- [x] T039a [US4] Add terms acceptance actions to OAuthCallbacksController in `app/controllers/oauth_callbacks_controller.rb`: `terms_acceptance` action (GET /auth/terms, render TOS/PP form with session-stored OAuth data displaying provider name, user name, and email) and `accept_terms` action (POST /auth/terms, create User from session OAuth data with terms_accepted_at, create OAuthIdentity, mark email as verified since provider-verified, create session, redirect to root)
- [x] T039b [US4] Add account linking actions to OAuthCallbacksController in `app/controllers/oauth_callbacks_controller.rb`: `link_account` action (GET /auth/link, render password confirmation form showing existing account email) and `confirm_link` action (POST /auth/link, authenticate existing user with provided password, create OAuthIdentity linking to that user, create session, redirect to root; on wrong password re-render with error)
- [x] T040 [US4] Create OAuth terms acceptance view at `app/views/oauth_callbacks/terms_acceptance.html.erb` with authentication layout: show provider name and user info (name, email from OAuth), `<wa-checkbox>` for TOS/PP acceptance, `<wa-button>` submit ("Complete Sign Up"), link to cancel and return to sign-in
- [x] T041 [US4] Create OAuth account linking view at `app/views/oauth_callbacks/link_account.html.erb` with authentication layout: explain that an account exists with this email, `<wa-input>` for existing account password (with visibility toggle), `<wa-button>` submit ("Link Account & Sign In"), link to cancel and sign in with existing credentials instead
- [x] T042 [US4] Create oauth_controller Stimulus controller at `app/javascript/controllers/oauth_controller.js` to handle OAuth button click loading states: disable button, show spinner/loading indicator on the clicked `<wa-button>`, re-enable on page return (handles browser back from provider)

### Tests for User Story 4

- [x] T042a [P] [US4] Create OAuthIdentity model test at `test/models/oauth_identity_test.rb`: test validations (provider presence/inclusion in allowed list, uid presence, uid uniqueness scoped to provider), test belongs_to user association
- [x] T042b [P] [US4] Create OAuthCallbacksController test at `test/controllers/oauth_callbacks_controller_test.rb`: test new user OAuth flow redirects to terms acceptance, test terms acceptance creates user and OAuthIdentity and session, test existing OAuth identity signs in directly, test email match redirects to account linking, test account linking with correct password creates OAuthIdentity, test account linking with wrong password re-renders with error, test failure action redirects with flash error; mock OmniAuth auth hash via `OmniAuth.config.mock_auth`

**Checkpoint**: OAuth sign in/up works for all 3 providers. Account linking with password confirmation. TOS/PP acceptance for new OAuth users.

---

## Phase 7: User Story 5 - Two-Factor Authentication (Priority: P3)

**Goal**: Users can enable TOTP-based 2FA, are prompted during sign-in, and can use recovery codes as backup.

**Independent Test**: Enable 2FA for account, sign out, sign in with password + TOTP code. Verify recovery code also works.

### Implementation for User Story 5

- [x] T044 [US5] Create TwoFactorAuthenticationController at `app/controllers/two_factor_authentication_controller.rb` with: `new` action (generate OTP secret via ROTP, store temporarily in session, generate QR code via rqrcode as SVG, render setup page); `create` action (verify submitted code against session secret, if valid create TwoFactorCredential with enabled=true, generate recovery codes via RecoveryCode.generate_for, render recovery_codes page with plaintext codes); `destroy` action (require current password + TOTP code, delete TwoFactorCredential and RecoveryCodes, redirect with success flash); `verify` action (GET, show 2FA code entry form during sign-in flow, user stored in session as pending_2fa_user_id); `confirm` action (POST, verify TOTP code or recovery code against pending user, if valid complete sign-in by creating session, if invalid re-render with error); `recovery_codes` action (GET, require auth, regenerate and display new recovery codes)
- [x] T045 [US5] Create 2FA setup view at `app/views/two_factor_authentication/new.html.erb` with authentication layout: heading "Enable Two-Factor Authentication", display QR code SVG, show text-based secret key for manual entry, `<wa-input>` for verification code (6 digits, inputmode numeric), `<wa-button>` submit ("Verify & Enable"), instructions for authenticator app setup
- [x] T046 [US5] Create 2FA verification view at `app/views/two_factor_authentication/verify.html.erb` with authentication layout: heading "Two-Factor Verification", subtext "Enter the code from your authenticator app", `<wa-input>` for 6-digit code (inputmode numeric, autofocus), `<wa-button>` submit ("Verify"), link "Use a recovery code instead" that toggles to recovery code input
- [x] T047 [US5] Create recovery codes display view at `app/views/two_factor_authentication/recovery_codes.html.erb` with authentication layout: heading "Save Your Recovery Codes", display codes in a grid/list with monospace font, `<wa-button>` to copy all codes to clipboard, `<wa-callout>` warning that codes are shown only once, `<wa-button>` "I've saved my codes" to continue
- [x] T048 [US5] Create two_factor_controller Stimulus controller at `app/javascript/controllers/two_factor_controller.js` with: auto-advance to submit when 6 digits entered, toggle between TOTP code and recovery code input, copy recovery codes to clipboard functionality, QR code display handling
- [x] T049 [US5] Update SessionsController `create` action in `app/controllers/sessions_controller.rb` to check if authenticated user has 2FA enabled: if yes, store user_id in session as `pending_2fa_user_id` (do NOT create full session yet), redirect to `/two_factor/verify`; the full session is only created after successful 2FA verification in TwoFactorAuthenticationController#confirm
- [x] T050 [US5] Update OAuthCallbacksController `create` action in `app/controllers/oauth_callbacks_controller.rb` to check 2FA on existing OAuth users: if user has 2FA enabled, store as pending_2fa_user_id and redirect to 2FA verify (same flow as password sign-in)

### Tests for User Story 5

- [x] T050a [P] [US5] Create TwoFactorCredential model test at `test/models/two_factor_credential_test.rb`: test `verify_code` with valid code returns true, test with invalid code returns false, test with drifted code within tolerance returns true, test `provisioning_uri` returns valid otpauth:// URI format, test otp_secret encryption at rest
- [x] T050b [P] [US5] Create RecoveryCode model test at `test/models/recovery_code_test.rb`: test `generate_for(user, count: 10)` creates 10 codes and returns plaintext array, test `consume!` sets used_at timestamp, test `used?` returns correct state, test code_digest is bcrypt hash not plaintext
- [x] T050c [P] [US5] Create TwoFactorAuthenticationController test at `test/controllers/two_factor_authentication_controller_test.rb`: test GET /two_factor/new generates QR code and renders setup, test POST /two_factor with valid code enables 2FA and shows recovery codes, test POST /two_factor with invalid code re-renders with error, test DELETE /two_factor requires password + TOTP code, test GET /two_factor/verify renders code entry form, test POST /two_factor/verify with valid TOTP completes sign-in, test POST /two_factor/verify with valid recovery code completes sign-in and invalidates code
- [x] T050d [US5] Create 2FA system test at `test/system/two_factor_auth_test.rb`: test full 2FA lifecycle (enable 2FA, sign out, sign in prompts for TOTP, enter code, access granted; also test recovery code path)
- [x] T050e [US5] Add 2FA account recovery path: add "Lost your device and recovery codes?" link on the 2FA verify page (T046) linking to a static recovery help view at `app/views/two_factor_authentication/recovery_help.html.erb` with instructions to contact support; add GET `/two_factor/recovery_help` route in `config/routes.rb`

**Checkpoint**: 2FA fully functional. Enable/disable, sign-in verification, recovery codes all working.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span multiple user stories, UI refinements, accessibility, and motion

- [x] T051 [P] Add subtle CSS animations and transitions to `app/assets/stylesheets/authentication.css`: fade-in for form container on page load, smooth transitions on segmented control tab switch, button hover/active states with scale transform, floating card subtle float animation on branded panel, input focus ring transitions
- [x] T052 [P] Ensure WCAG 2.1 AA compliance across all authentication views: verify color contrast ratios (especially white text on #8B5CF6), add proper `aria-label` attributes to icon buttons (password visibility toggle, OAuth buttons), ensure all form inputs have associated labels, verify keyboard navigation through all forms and controls, add `aria-live` regions for dynamic error messages
- [x] T053 [P] Add responsive CSS refinements to `app/assets/stylesheets/authentication.css`: ensure all auth screens render correctly at mobile (<640px), tablet (640-1024px), and desktop (>1024px) breakpoints; mobile uses stacked layout per .pen Mobile frame; tablet uses condensed split or stacked; desktop uses full split layout
- [x] T054 Add missing UI/UX screens to `designs/initial-screens.pen`: Password Reset Request screen, Password Reset New Password screen, Email Verification Pending screen, OAuth Terms Acceptance screen, OAuth Account Linking screen, 2FA Setup screen (with QR code), 2FA Verify screen, Recovery Codes screen - all following the existing design language (branded left/top panel, form content area, same color palette and typography)
- [x] T055 [P] Add Turbo Frame integration for seamless tab switching between Sign In and Sign Up forms: wrap form content in `<turbo-frame>` tags so switching between tabs does not require full page reload; update segmented control links to use Turbo Frame targeting
- [x] T056 Review and validate all security measures: verify CSRF protection on all forms (Rails authenticity token), confirm rate limiting on SessionsController and PasswordsController, verify password reset tokens are single-use (scoped to password_digest), confirm OmniAuth CSRF protection middleware is active, ensure session fixation protection on sign-in
- [x] T057 Run full quickstart.md verification flow: test sign-up, sign-in, password reset, OAuth (with test credentials), 2FA setup, and email verification flows per `specs/001-user-auth/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **US1 Sign Up (Phase 3)**: Depends on Foundational
- **US2 Sign In (Phase 4)**: Depends on Foundational (can run in parallel with US1 since different controllers/views)
- **US3 Password Reset (Phase 5)**: Depends on Foundational
- **US4 OAuth (Phase 6)**: Depends on Foundational + OmniAuth config from Setup
- **US5 2FA (Phase 7)**: Depends on Foundational + US2 (modifies SessionsController sign-in flow)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Independent after Foundational - no dependency on other stories
- **US2 (P1)**: Independent after Foundational - can parallel with US1 (different files)
- **US3 (P2)**: Independent after Foundational - uses generated PasswordsController
- **US4 (P2)**: Independent after Foundational - new controller/views
- **US5 (P3)**: Depends on US2 completion (modifies SessionsController#create for 2FA check)

### Within Each User Story

- Models/migrations before controllers
- Controllers before views
- Stimulus controllers can parallel with views (different files)
- Mailers can parallel with controllers (different files)

### Parallel Opportunities

**Phase 1 Setup**: T007 and T008 can run in parallel (different partials)
**Phase 2 Foundational**: T011, T012 in parallel (different migrations); T015, T016, T017 in parallel (different models); T019, T020 in parallel (different config files)
**US1 + US2**: Can run in parallel after Foundational (different controllers and views)
**US3 + US4**: Can run in parallel after Foundational (completely independent files)
**Phase 8 Polish**: T051, T052, T053, T055 all in parallel (different concerns/files)

---

## Parallel Example: After Foundational Phase

```bash
# US1 and US2 can start simultaneously:
# Developer A (US1 - Sign Up):
Task T021: RegistrationsController
Task T022: Sign Up view
Task T027: form_validation_controller.js (parallel with T022)
Task T028: password_visibility_controller.js (parallel with T022)
Task T023-T024: Email verification mailer (parallel with T021)

# Developer B (US2 - Sign In):
Task T030: SessionsController
Task T031: Sign In view
Task T032: Account lockout logic in User model
Task T033: Lockout display
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: US1 - Sign Up
4. Complete Phase 4: US2 - Sign In
5. **STOP and VALIDATE**: Both sign-up and sign-in work independently
6. Deploy/demo - users can create accounts and sign in

### Incremental Delivery

1. Setup + Foundational -> Foundation ready
2. US1 (Sign Up) + US2 (Sign In) -> MVP! Users can register and authenticate
3. US3 (Password Reset) -> Users can recover access
4. US4 (OAuth) -> Reduced friction, social sign-in
5. US5 (2FA) -> Enhanced security for power users
6. Polish -> Animations, accessibility, responsive refinements

### Task Summary

| Phase | Tasks | Parallel Tasks |
|-------|-------|---------------|
| Phase 1: Setup | T001-T008 (8) | 2 |
| Phase 2: Foundational | T009-T020 (12) | 7 |
| Phase 3: US1 Sign Up | T021-T029e (14: 9 impl + 5 test) | 4 test tasks [P] |
| Phase 4: US2 Sign In | T030-T033b (6: 4 impl + 2 test) | 1 test task [P] |
| Phase 5: US3 Password Reset | T034-T038c (8: 5 impl + 3 test) | 2 test tasks [P] |
| Phase 6: US4 OAuth | T039-T042b (7: 5 impl + 2 test) | 2 test tasks [P] |
| Phase 7: US5 2FA | T044-T050e (12: 8 impl + 4 test) | 3 test tasks [P] |
| Phase 8: Polish | T051-T057 (7) | 4 |
| **Total** | **74 tasks** | **25 parallelizable** |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in the same phase
- [Story] label maps each task to its user story for traceability
- Each user story is independently completable and testable after Foundational
- Web Awesome Pro components used throughout: `<wa-input>`, `<wa-button>`, `<wa-checkbox>`, `<wa-callout>`, `<wa-icon>`, `<wa-tooltip>`
- Font Awesome Pro icons used for: OAuth provider logos, password visibility toggle, form field icons, decorative elements
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
