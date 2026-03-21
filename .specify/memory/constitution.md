<!--
  Sync Impact Report
  ====================
  Version change: N/A (initial) -> 1.0.0
  Modified principles: N/A (initial creation)
  Added sections:
    - Core Principles (7 principles)
    - Technology Stack & Constraints
    - Development Workflow & Quality Gates
    - Governance
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md: ✅ No updates needed
      (Constitution Check section is dynamic, filled at plan time)
    - .specify/templates/spec-template.md: ✅ No updates needed
      (Template is technology-agnostic by design)
    - .specify/templates/tasks-template.md: ✅ No updates needed
      (Phase structure accommodates all principle-driven task types)
    - .specify/templates/agent-file-template.md: ✅ No updates needed
    - .specify/templates/checklist-template.md: ✅ No updates needed
    - README.md: ⚠️ Pending (default Rails README, update when
      first feature is implemented)
  Follow-up TODOs: None
-->

# Facere Constitution

## Core Principles

### I. Vanilla Rails First

All features MUST leverage Ruby on Rails 8.1 conventions and built-in
capabilities before reaching for external solutions. This includes
Active Record, Action Controller, Action View, Active Job, Action Cable,
Active Storage, and all Hotwire tools (Turbo Drive, Turbo Frames,
Turbo Streams, Stimulus). When uncertain about available Rails features,
consult the Rails Guides (https://guides.rubyonrails.org). The Fizzy
codebase by 37signals (https://github.com/basecamp/fizzy) serves as
a reference for modern, vanilla Rails patterns.

- MUST use Rails conventions over custom abstractions
- MUST use Hotwire (Turbo + Stimulus) for all front-end interactivity
- MUST NOT introduce JavaScript frameworks that duplicate Hotwire
  capabilities
- MUST follow Rails directory structure and naming conventions
- MUST use Importmap or Propshaft as Rails 8.1 provides

### II. Library-First

ALWAYS search for existing, well-maintained solutions before writing
custom code. Every line of custom code is a liability requiring
maintenance, testing, and documentation.

- MUST evaluate existing gems before writing custom Ruby code
- MUST consider third-party services for common functionality
  (authentication, email delivery, file storage)
- Custom code IS justified when:
  - Business logic is unique to the Facere domain
  - Performance-critical paths have special requirements
  - External dependencies would be overkill for the use case
  - Security-sensitive code requires full control
  - Existing solutions fail to meet requirements after evaluation
- MUST NOT suffer from NIH (Not Invented Here) syndrome

### III. Joyful User Experience

Facere MUST deliver a fun, friendly, and delightful experience that
makes users want to return. The UI/UX is the primary differentiator
and MUST NOT feel generic or utilitarian.

- MUST be fully responsive across all mobile devices and desktop screens
- MUST use Web Awesome Pro (https://webawesome.com) for all UI
  components, theming, and the design system
- MUST use Font Awesome Pro (https://fontawesome.com) for all iconography
- MUST ensure Web Awesome components integrate cleanly with Stimulus
  controllers
- MUST prioritize micro-interactions, animations, and visual polish
  that convey friendliness
- MUST NOT ship generic, unstyled, or purely functional interfaces

### IV. Clean Architecture & Domain-Driven Design

Follow DDD principles and ubiquitous language throughout the codebase.
Separate domain entities from infrastructure concerns and keep business
logic independent of framework specifics where practical.

- MUST use domain-specific naming (e.g., `TaskCompleter`,
  `ListOrganizer`) over generic names (`utils`, `helpers`, `common`)
- MUST keep business logic out of controllers; controllers orchestrate,
  models and service objects encapsulate logic
- MUST keep database queries out of controllers; use scopes, query
  objects, or model methods
- MUST maintain clear bounded contexts between application domains
- Each module/class MUST have a single, clear purpose

### V. Code Quality & Readability

Code MUST be clean, concise, and immediately understandable. Favor
explicitness over cleverness.

- MUST use early return pattern over nested conditionals
- MUST avoid nesting deeper than 3 levels
- MUST keep methods under 50 lines and classes/files under 200 lines;
  decompose when exceeding these limits
- MUST avoid code duplication through reusable methods and concerns
- MUST handle errors properly with appropriate exception types
- MUST NOT use generic naming patterns (`utils.rb`, `helpers/misc.rb`)
- Components and methods that cannot be reused elsewhere MAY stay in
  the same file, but the file MUST still respect the 200-line limit

### VI. Separation of Concerns

Strict boundaries MUST exist between application layers. Mixing
responsibilities creates brittle, untestable code.

- MUST NOT mix business logic with view templates or controllers
- MUST NOT place database queries directly in controllers
- MUST use service objects, form objects, or query objects when
  controller actions exceed simple CRUD
- MUST keep Stimulus controllers focused on DOM interaction, delegating
  business decisions to the server via Turbo
- MUST separate configuration from code using Rails credentials and
  environment-appropriate config

### VII. Simplicity & YAGNI

Start simple. Build only what is needed now. Complexity MUST be
justified by current requirements, not hypothetical future needs.

- MUST NOT add features, abstractions, or configurability beyond what
  is currently required
- MUST NOT create premature abstractions; three similar lines of code
  is better than a premature helper
- MUST NOT add error handling for scenarios that cannot occur
- MUST NOT use feature flags or backward-compatibility shims when
  direct changes suffice
- MUST justify any added complexity with a concrete, current need
- MUST prefer deleting unused code over commenting it out or renaming

## Technology Stack & Constraints

- **Framework**: Ruby on Rails 8.1 (latest stable)
- **Ruby Version**: Per `.ruby-version` in repository root
- **Front-End Interactivity**: Hotwire (Turbo Drive, Turbo Frames,
  Turbo Streams, Stimulus)
- **UI Components & Theming**: Web Awesome Pro
- **Iconography**: Font Awesome Pro
- **Database**: SQLite (Rails 8.1 default for development); production
  database per deployment configuration
- **Asset Pipeline**: Propshaft + Importmap (Rails 8.1 defaults)
- **Deployment**: Kamal (per existing `.kamal/` configuration)
- **Testing**: Minitest (Rails default)
- **Reference Codebase**: Fizzy by 37signals
  (https://github.com/basecamp/fizzy)
- **Responsive Design**: MUST support mobile-first responsive layouts
  across phones, tablets, and desktop screens

All technology choices MUST align with the Vanilla Rails First
principle. Deviations require explicit justification in the relevant
plan document's Complexity Tracking table.

## Development Workflow & Quality Gates

- **Convention over Configuration**: Follow Rails conventions for file
  placement, naming, routing, and database schema
- **Test Coverage**: All new features MUST include test coverage using
  Minitest; system tests for critical user flows
- **Code Review**: All changes MUST pass review against constitution
  principles before merge
- **Accessibility**: UI components MUST meet WCAG 2.1 AA standards
  as supported by Web Awesome Pro
- **Performance**: Pages MUST render server-side HTML via Turbo; avoid
  full-page reloads for in-app navigation
- **Security**: Follow Rails security best practices (CSRF protection,
  parameterized queries, Content Security Policy); validate at system
  boundaries only
- **Commit Discipline**: Commit after each logical unit of work with
  clear, descriptive messages

### CI Pipeline — All Checks MUST Pass

Every feature MUST pass the full CI pipeline before being considered
complete. Zero errors across all checks:

1. **Lint**: `bin/rubocop` — zero offenses
2. **Security Scan**: `bin/brakeman --no-pager` — zero warnings
3. **Dependency Audit**: `bin/bundler-audit` — zero advisories
4. **Unit & Integration Tests**: `bin/rails test` — zero failures
5. **System Tests**: `bin/rails test:system` — zero failures
6. **JS Dependency Audit**: `bin/importmap audit` — zero vulnerabilities

### Feature Completion Checklist

A feature is NOT complete until:

- All implementation tasks are marked done
- `bin/rubocop` passes with zero offenses
- `bin/brakeman --no-pager` passes with zero warnings
- `bin/rails test` passes with zero failures
- `bin/rails test:system` passes with zero failures
- Spec documents (spec.md, plan.md, tasks.md) are updated with
  implementation learnings

## Governance

This constitution is the authoritative source of project principles
and constraints for Facere. All design decisions, code reviews, and
implementation plans MUST verify compliance with these principles.

- **Amendments** require: (1) documented rationale, (2) review of
  impact on existing code and templates, (3) version bump per semantic
  versioning rules below
- **Versioning**: MAJOR for principle removals or incompatible
  redefinitions; MINOR for new principles or material expansions;
  PATCH for clarifications and typo fixes
- **Compliance Review**: Every PR MUST be checked against the Core
  Principles. Violations MUST be resolved or justified in a Complexity
  Tracking table before merge
- **Runtime Guidance**: Use the agent development guidelines file
  (generated from `agent-file-template.md`) for day-to-day development
  reference

**Version**: 1.1.0 | **Ratified**: 2026-03-05 | **Last Amended**: 2026-03-21
