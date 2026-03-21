# Facere Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-05

## Active Technologies

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

- 001-user-auth: User authentication (sign up, sign in, password
  reset, OAuth, 2FA, email verification)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
