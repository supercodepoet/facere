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
- MUST use Font Awesome Pro (https://fontawesome.com) for all iconography;
  icons use standard `<i>` tags with Font Awesome classes
  (e.g. `<i class="fa-light fa-icon-name"></i>`)
- MUST NOT use Web Awesome custom elements (`wa-icon`, `wa-button`,
  `wa-dropdown`, `wa-dialog`, `wa-input`, etc.) — use standard HTML
  elements instead. Web Awesome was removed in feature 007 due to
  styling conflicts and inconsistent kit loading across layouts
- MUST prioritize micro-interactions, animations, and visual polish
  that convey friendliness
- MUST NOT ship generic, unstyled, or purely functional interfaces
- MUST validate all UI implementation against `.pen` design file
  screenshots — the design file is the source of truth for spacing,
  fonts, colors, and component sizes

### IV. Clean Architecture & Domain-Driven Design

Follow DDD principles and ubiquitous language throughout the codebase.
Separate domain entities from infrastructure concerns and keep business
logic independent of framework specifics where practical.

- MUST use domain-specific naming (e.g., `TaskCompleter`,
  `ListOrganizer`) over generic names (`utils`, `helpers`, `common`)
- MUST keep business logic out of controllers; controllers orchestrate,
  models and service objects encapsulate logic
- MUST keep database queries out of controllers AND views; use scopes,
  query objects, or model methods. Views MUST only read instance
  variables set by the controller — never issue queries directly
- MUST eager-load associations (`.includes()`) when rendering
  collections to prevent N+1 queries. Use `.size` (reads loaded
  collection) instead of `.count` (forces SQL COUNT) on eager-loaded
  associations
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
- MUST wrap multi-record creation/update operations in `transaction`
  blocks for all-or-nothing semantics
- MUST produce valid HTML — never nest interactive elements (`<button>`
  inside `<a>`, `<a>` inside `<button>`)
- **No duplicate DOM IDs**: `turbo_frame_tag dom_id(obj)` creates an
  element with an `id`. MUST NOT also set the same `id` on an inner
  element. Duplicate IDs break JS lookups and Turbo replacements
- **`button_to` with blocks**: When using a block for button content
  (e.g., icons), do NOT pass a label string as the first argument —
  the block provides the content, the first arg MUST be the URL
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
- **Iconography**: Font Awesome Pro (CDN kit); icons use standard `<i>` tags
  with Font Awesome classes (e.g. `<i class="fa-light fa-icon-name"></i>`).
  Use `fa-light` (300 weight) as the default icon style — `fa-thin` (100)
  is too light for readability. Use `fa-solid` for emphasis (e.g., active
  states, context menu trigger dots)
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

### Lexxy Integration Rules

Learned through implementation of TODO Item Detail feature (004):

- **Lexxy JS pin**: Do NOT use `bin/importmap pin lexxy` — it downloads
  a wrong npm package (a tiny lexer library, not the editor). Use
  `pin "lexxy", to: "lexxy.min.js"` which resolves through Propshaft
  to the gem's bundled 692KB editor JS. Also pin `@rails/activestorage`
  as Lexxy imports it internally:
  `pin "@rails/activestorage", to: "activestorage.esm.js"`
- **Lexxy replaces Trix**: Remove `import "trix"` and
  `import "@rails/actiontext"` from application.js, replace with
  `import "lexxy"`. Set
  `config.lexxy.override_action_text_defaults = true` in an
  initializer. Update ActionText content partial class from
  `trix-content` to `lexxy-content`
- **Lexxy toolbar theming**: Use CSS custom properties
  (`--lexxy-color-ink`, `--lexxy-toolbar-gap`,
  `--lexxy-toolbar-icon-size`, `--lexxy-color-canvas`, etc.) to style
  the toolbar. Target `lexxy-toolbar` and
  `.lexxy-editor__toolbar-button` for button styling
- **Lexxy auto-save**: Listen for `lexxy:change` event in a Stimulus
  controller, debounce 2 seconds, submit form via `fetch()`. Save
  immediately on `disconnect()` to prevent data loss during navigation
- **Lexxy editor in cards**: Wrap `f.rich_text_area` in a
  `.notes-editor-wrap` (or `.comment-editor-wrap`) div with
  `border: 1px solid #D4D4D8; border-radius: 12px; overflow: hidden`.
  Style toolbar and bottom bar with `#F4F4F5` background and
  `border-top/bottom: 1px solid #D4D4D8` for visual separation.
  Set `.lexxy-editor__content` padding and min-height via scoped CSS
- **Lexxy editor text size**: Set `font-size: 14px; line-height: 1.6`
  on `.lexxy-editor__content` to match the view/display mode text size.
  Lexxy's default font size may differ from the content display
- **Lexxy for comments (dual-field)**: When adding rich text to an
  existing plain-text model, add `has_rich_text :rich_body` alongside
  the existing `body` column. Make `body` validation conditional
  (`unless: :rich_body?`). Display uses `rich_body` with `body` fallback.
  This avoids a data migration for existing records

### Turbo & Stimulus Integration Rules

Learned through implementation of TODO List Items feature (003):

- **Turbo Frame navigation**: Links inside `turbo_frame_tag` are
  intercepted by Turbo. For full-page navigation, add
  `data: { turbo_frame: "_top" }` to the link
- **Turbo Stream responses on detail pages**: If a controller action
  responds with Turbo Streams that target list-view partials, those
  streams will fail on detail pages where the targets don't exist.
  Use `data: { turbo: false }` on detail-page forms to force HTML
  redirects
- **Draggable turbo-frames**: When using HTML5 drag-and-drop with Turbo
  Frames, put `draggable="true"` on the `turbo_frame_tag` itself (not
  inner elements). Use `data-*` attributes for identification.
  Add `turbo-frame { display: block; }` in CSS
- **Position management**: When prepending items at position 0, shift
  existing positions BEFORE saving the new record (in a transaction).
  Shifting after save will also increment the new record
- **Inline creation without forms**: If inline creation uses plain
  `<div>` + `<input>` (not `<form>`), use `fetch()` with FormData
  instead of `requestSubmit()`. `requestSubmit()` only works on
  `<form>` elements
- **Scoped associations in controllers**: When `has_many` uses a
  default scope (e.g., `-> { active }`), controller `find` calls
  will exclude scoped-out records. Use an unscoped association
  for lookups that should operate on all records (e.g., archived)
- **`button_to` in flex layouts**: `button_to` generates `<form><button>`
  wrappers. Inside flex containers, these `<form>` elements break layout
  (block elements with default margins, hidden inputs leak into flex
  flow). Prefer `link_to` with `data: { turbo_method: :patch }` (or
  `:delete`) for simple actions in flex layouts (checklist toggles,
  status buttons). If `button_to` must be used, add
  `.parent form { display: contents; }` CSS — but be aware hidden
  inputs may still cause spacing issues
- **`before_action only:` validates action existence (Rails 8.1)**:
  `before_action :callback, only: %i[update destroy]` will raise
  `AbstractController::ActionNotFound` if `update` is not defined on
  the controller. Always verify all action names in `only:` filters
  reference actual controller actions
- **`ActiveRecord::Associations::Preloader` for show actions**: When
  `before_action` already loads a record and `show` needs eager loading,
  use `Preloader.new(records: [@record], associations: [...]).call`
  instead of re-fetching with `includes(...).find()`

### Turbo Frame & Stream Patterns for Inline Editors

Learned through implementation of Tag Management feature (009):

- **Sibling frames, not nested frames**: When a Turbo Stream replaces
  a frame (e.g., `item_tags_` with updated tag pills), any child
  turbo-frames inside it are destroyed. If you need a persistent
  editor alongside replaceable content, make them **sibling** frames
  under a common parent — not parent-child. Example: `show.html.erb`
  wraps both `item_tags_` (replaceable) and `tag_editor_` (persistent)
  in a shared `div` with the Stimulus controller
- **Turbo Stream replacements MUST preserve Stimulus data attributes**:
  When a Turbo Stream replaces a turbo-frame element, the replacement
  HTML MUST include all `data-*-target` and `data-src` attributes
  that the original element had. Without these, the Stimulus controller
  loses its targets and throws "Missing target element" errors
- **Use `data-turbo-frame="_top"` for actions inside editor frames**:
  Forms and links inside a `turbo-frame` are scoped to that frame by
  default. If the server responds with Turbo Streams (not a frame
  response), use `data: { turbo_frame: "_top" }` to make the request
  a top-level Turbo Drive request. This ensures Turbo Stream responses
  are processed correctly regardless of frame nesting
- **Lazy-load turbo frames on demand, not on page load**: For editor
  popovers that should only appear on click, render the turbo-frame
  WITHOUT `src` or `loading="lazy"`. Store the URL in `data-src` and
  set `frame.src = frame.dataset.src` via Stimulus when the user
  clicks the trigger. Listen for `turbo:frame-load` (once) to show
  the popover after content arrives
- **Context menus inside scrollable containers**: Elements with
  `overflow-y: auto` (e.g., scrollable lists) clip absolutely-
  positioned children. For context menus (ellipsis dropdowns), use
  `position: fixed` on the menu and calculate position via
  `getBoundingClientRect()` in JS. Set `z-index: 99999` to ensure
  the menu renders above all layers
- **Single controller for multiple context menus**: When multiple
  rows each have an ellipsis menu, do NOT use a separate `dropdown`
  controller per row — they can't coordinate. Instead, manage all
  menus from the parent Stimulus controller with a `toggleEllipsis`
  action that calls `closeAllEllipsis()` before opening the clicked
  menu. This guarantees only one menu is open at a time
- **Always-active outside-click listener for popovers**: Register
  the `document` click listener in `connect()` and remove in
  `disconnect()` — not in open/close methods. If registered only
  on open, Turbo Stream replacements can disconnect/reconnect the
  controller and lose the listener, leaving the popover stuck open

### Custom Dropdown & Modal Patterns

Learned through UI component modernization (007):

- **Dropdown pattern**: Use `dropdown_controller.js` Stimulus controller
  with `.dropdown-wrap` > trigger button + `.dropdown-menu` div. The
  controller handles toggle, close-on-outside-click, and dispatches
  `dropdown:select` events with `{ detail: { item: { value } } }`
- **Modal pattern**: Use `modal_controller.js` with
  `.delete-modal-overlay` > `.delete-modal-panel`. Open by adding
  `.delete-modal--open` class. Close via `data-action="click->modal#close"`
  or backdrop click. Use `stopPropagation` on the panel to prevent
  backdrop close when clicking inside
- **Dropdown z-index**: Set to `9999` to ensure dropdowns render above
  all content including sticky headers and overflow:hidden containers
- **Confirmation modals over turbo_confirm**: For destructive actions
  (delete item, delete list), use a styled modal with Cancel + Delete
  buttons rather than the browser's native `confirm()` dialog. This
  provides a consistent, on-brand UX

### Stimulus Controller Scope Rules

Learned through inline item hint fix (007):

- **Target scope**: `data-{controller}-target` attributes MUST be
  descendants of the element with `data-controller`. Sibling elements
  outside the controller element will NOT be found as targets
- **Template cloning**: When a `<template>` is cloned and inserted into
  the DOM, Stimulus `connect()` fires immediately. If checking for
  existing DOM elements (e.g., `.todo-item`), also schedule a
  `requestAnimationFrame` callback as a fallback for timing edge cases
- **Form vs wrapper controller**: If a Stimulus controller needs targets
  both inside and outside a `<form>`, place the controller on a common
  ancestor wrapper div, not on the form itself. Use
  `this.element.querySelector("form").requestSubmit()` to submit

### Collaboration & Multi-User Authorization Rules

Learned through implementation of List Collaboration feature (005):

- **Shared resource query pattern**: When a resource can be owned OR
  shared, use an OR query with subselects to find it:
  ```ruby
  TodoList.where(id: params[:id])
    .where(id: Current.user.todo_lists.select(:id))
    .or(TodoList.where(id: params[:id])
      .where(id: Current.user.shared_lists.select(:id)))
    .first!
  ```
  Extract this into a concern method to avoid repetition across
  controllers. The `first!` raises `RecordNotFound` → 404 for
  unauthorized users
- **Authorization concern pattern**: Use a `ListAuthorization` concern
  with `authorize_list_access!`, `authorize_editor!`, `authorize_owner!`
  methods. Expose `current_list_role`, `list_editor?`, `list_owner?` as
  helper methods for views via `helper_method`. Apply as `before_action`
  filters on controller actions
- **Brakeman and `:role` params**: Brakeman flags `:role` in
  `permit()` as mass assignment risk. Fix by extracting the role
  param separately and validating against an allowlist:
  ```ruby
  permitted = params.require(:invitation).permit(:email)
  role = params.dig(:invitation, :role)
  permitted[:role] = ROLES.include?(role) ? role : "editor"
  ```
- **Turbo Streams broadcasting with controller helpers**: Partials
  that use controller helper methods (e.g., `list_editor?`) CANNOT
  be rendered in broadcast callbacks because there is no controller
  context. Use `broadcast_refresh_to` (Turbo 8 page refresh) instead
  of `broadcast_replace_to` / `broadcast_append_to` when partials
  depend on authorization helpers. `broadcast_refresh_to` triggers a
  morph-based page refresh on subscribed clients — no partial needed
- **`turbo_stream_from` authorization**: Signed stream names
  (generated by `turbo_stream_from` in the view) provide implicit
  authorization. Only users who can render the view receive the signed
  token. No custom ActionCable channel or `#subscribed` auth needed
- **`generates_token_for` with status invalidation**: Key the token
  on a field that changes on use (e.g., `status`) so the token
  auto-invalidates after acceptance/cancellation:
  ```ruby
  generates_token_for :acceptance, expires_in: 30.days do
    status  # token invalidates when status changes
  end
  ```
- **Invitation resend pattern**: When re-inviting an already-pending
  email, find the existing active invitation and resend the email
  rather than creating a duplicate. Check with `.active.find_by(email:)`
  before building a new record
- **`Current.user` nil guard in model callbacks**: Model callbacks
  triggered by `after_save` or `after_commit` may fire outside request
  context (console, background jobs). Always guard `Current.user`
  before referencing it:
  ```ruby
  return unless Current.user
  ```
- **Pending invitation cancellation**: Always scope `destroy` actions
  for invitations to `status: "pending"`. Use `find_by!` with the
  status constraint. Cancelling accepted/expired invitations corrupts
  token state
- **Integration test 404 pattern**: In `ActionDispatch::IntegrationTest`,
  Rails rescues `ActiveRecord::RecordNotFound` and returns 404. Do NOT
  use `assert_raises(ActiveRecord::RecordNotFound)` — use
  `assert_response :not_found` instead
- **Invitation auto-accept after auth**: Store the invitation token in
  `session[:pending_invitation_token]` when an unauthenticated user
  clicks an accept link. Check and consume this token in both
  `SessionsController#create` and `RegistrationsController#create`
  after successful authentication. Return the accepted list from the
  helper to redirect the user directly to it

## Development Workflow & Quality Gates

- **Convention over Configuration**: Follow Rails conventions for file
  placement, naming, routing, and database schema
- **Test Coverage**: All new features MUST include test coverage using
  Minitest; system tests for critical user flows
- **Code Review**: All changes MUST pass review against constitution
  principles before merge
- **Accessibility**: UI components MUST meet WCAG 2.1 AA standards
- **Performance**: Pages MUST render server-side HTML via Turbo; avoid
  full-page reloads for in-app navigation
- **Security**: Follow Rails security best practices (CSRF protection,
  parameterized queries, Content Security Policy); validate at system
  boundaries only. All controller actions MUST scope queries to the
  current user (`Current.user.association`) for authorization. Return
  404 (not 403) for unauthorized resource access to avoid revealing
  resource existence. Strong params MUST exclude `user_id` and other
  ownership fields. Enforce uniqueness constraints at both model AND
  database level (e.g., case-insensitive unique indexes for SQLite)
- **Server-side ownership enforcement**: Even for "single-user stub"
  features, NEVER permit arbitrary foreign key IDs from client params.
  Always force ownership fields server-side (e.g.,
  `permitted[:assigned_to_user_id] = Current.user.id`)
- **Test Coverage — Security**: Every controller MUST have tests for
  authentication (unauthenticated redirects) and authorization (other
  user's resources return 404) on all actions. Parameter injection
  tests MUST verify ownership fields cannot be overridden via params
- **Cross-resource parameter validation**: When permitting foreign key
  params like `parent_id`, MUST validate the referenced record belongs
  to the same parent resource. Without this, users can create
  cross-resource associations (e.g., replying to a comment on a
  different item). Add model-level validation:
  `validate :parent_belongs_to_same_resource`
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
7. **CI Secrets**: `RAILS_MASTER_KEY` MUST be stored as a GitHub secret.
   Active Record encryption test keys MUST be configured in
   `config/environments/test.rb` as a fallback

### Feature Completion Checklist

A feature is NOT complete until:

- All implementation tasks are marked done
- `bin/rubocop` passes with zero offenses
- `bin/brakeman --no-pager` passes with zero warnings
- `bin/rails test` passes with zero failures
- `bin/rails test:system` passes with zero failures
- Spec documents (spec.md, plan.md, tasks.md) are updated with
  implementation learnings
- Copilot code review findings addressed or documented as intentional
  deviations

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

**Version**: 1.7.0 | **Ratified**: 2026-03-05 | **Last Amended**: 2026-03-25
