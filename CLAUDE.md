# Facere Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-05

## Active Technologies
- Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive + Stimulus), Web Awesome Pro (CDN kit), Font Awesome Pro (CDN kit), bcrypt (existing) (002-todo-lists)
- Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive + Turbo Streams + Turbo Frames + Stimulus), Web Awesome Pro (CDN kit), Font Awesome Pro (CDN kit), ActionText (Rails built-in, for notes), Active Storage (Rails built-in, for attachments) (003-todo-list-items)
- Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive + Turbo Streams + Turbo Frames + Stimulus), Web Awesome Pro (CDN), Font Awesome Pro (CDN), Lexxy (~> 0.1.26.beta, new), ActionText (Rails built-in), Active Storage (Rails built-in) (004-todo-item-detail)
- Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, Stimulus), ActionCable (already configured — connection + auth in place, no channels yet), Action Mailer (existing mailers for email verification and password reset), Web Awesome Pro (CDN), Font Awesome Pro (CDN), Lexxy, Active Storage, ActionTex (005-list-collaboration)
- SQLite (all environments), Solid Cable (production ActionCable adapter) (005-list-collaboration)

- Ruby 4.0.1 / Rails 8.1.2 (001-user-auth)
- Hotwire: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus
- UI: Web Awesome Pro (CDN kit), Font Awesome Pro (CDN kit)
- Auth: bcrypt, OmniAuth (google-oauth2, facebook, apple), rotp, rqrcode
- Database: SQLite (all environments)
- Asset Pipeline: Propshaft + Importmap
- Deployment: Kamal
- Testing: Minitest + Capybara + Selenium

## Project Structure

```text
app/
├── controllers/     # Rails controllers (thin, orchestration only)
├── models/          # Active Record models (business logic here)
├── views/           # ERB templates with Web Awesome components
├── mailers/         # Action Mailer classes
├── javascript/
│   └── controllers/ # Stimulus controllers (DOM interaction only)
└── assets/
    └── stylesheets/ # CSS files

config/              # Rails configuration
db/migrate/          # Database migrations
test/                # Minitest tests (controllers, models, system)
```

## Commands

```bash
bin/dev              # Start development server
bin/rails test       # Run all tests
bin/rails test:system # Run system tests
bin/rails db:migrate # Run migrations
bin/rails credentials:edit # Edit encrypted credentials
```

## Code Style

- Ruby: Follow Rails Omakase style (rubocop-rails-omakase)
- Early returns over nested conditionals
- Methods < 50 lines, files < 200 lines
- Domain-specific naming (no utils/helpers/common)
- Business logic in models/service objects, not controllers
- Stimulus controllers for DOM only; server logic via Turbo

## Recent Changes
- 005-list-collaboration: Added Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, Stimulus), ActionCable (already configured — connection + auth in place, no channels yet), Action Mailer (existing mailers for email verification and password reset), Web Awesome Pro (CDN), Font Awesome Pro (CDN), Lexxy, Active Storage, ActionTex
- 004-todo-item-detail: Added Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive + Turbo Streams + Turbo Frames + Stimulus), Web Awesome Pro (CDN), Font Awesome Pro (CDN), Lexxy (~> 0.1.26.beta, new), ActionText (Rails built-in), Active Storage (Rails built-in)
- 003-todo-list-items: Added Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive + Turbo Streams + Turbo Frames + Stimulus), Web Awesome Pro (CDN kit), Font Awesome Pro (CDN kit), ActionText (Rails built-in, for notes), Active Storage (Rails built-in, for attachments)

  reset, OAuth, 2FA, email verification)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
