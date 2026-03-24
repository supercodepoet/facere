# Implementation Plan: TODO List Management

**Branch**: `002-todo-lists` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-todo-lists/spec.md`

## Summary

Implement full CRUD for TODO Lists within the existing Rails 8.1 application. Users can view their lists (with blank slate for empty state), create new lists with name/color/icon/description/template, edit list details, and delete lists with confirmation. The UI follows the `initial-screens.pen` visual reference using Font Awesome Pro icons and standard HTML elements styled with CSS, with Hotwire (Turbo + Stimulus) for all interactivity. Templates (Blank, Project, Weekly, Shopping) pre-populate lists with named sections and starter items on creation.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive + Stimulus), Font Awesome Pro (CDN kit), bcrypt (existing)
**Storage**: SQLite (all environments)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web (responsive — desktop + mobile)
**Project Type**: Web application
**Performance Goals**: Standard web app — pages render in <1s, form submissions in <500ms
**Constraints**: Server-rendered HTML via Turbo, no SPA frameworks
**Scale/Scope**: 7 screens (4 desktop + 2 mobile + 1 modal), 3 new database tables, 1 controller, 5 Stimulus controllers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Standard Rails MVC + resourceful routes + Hotwire. No external JS frameworks. |
| II. Library-First | PASS | Font Awesome Pro for icons. Standard HTML elements with CSS. |
| III. Joyful User Experience | PASS | Following .pen visual reference with micro-interactions, branded illustrations, polished blank slates. |
| IV. Clean Architecture & DDD | PASS | Domain-specific naming (TodoList, TodoSection, TodoItem). Business logic in models. |
| V. Code Quality & Readability | PASS | Standard CRUD controller, focused models, isolated Stimulus controllers. |
| VI. Separation of Concerns | PASS | Stimulus for DOM (pickers, modals), Turbo for navigation, models for logic. |
| VII. Simplicity & YAGNI | PASS | Only building screens in spec. Template data as constants, not a separate system. |

### Post-Design Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | `resources :todo_lists` routing, standard controller actions, Turbo Drive navigation. |
| II. Library-First | PASS | Font Awesome Pro icons via `<i>` tags. Standard HTML form elements with CSS. Custom error banner to match .pen design exactly. |
| III. Joyful User Experience | PASS | Blank slates with illustrations, success toasts, color-coded list cards, smooth transitions. |
| IV. Clean Architecture & DDD | PASS | `TodoList#apply_template!` encapsulates seeding logic. Scoped queries via `Current.user.todo_lists`. |
| V. Code Quality & Readability | PASS | Controller <50 lines per action, models focused, CSS organized in single feature file. |
| VI. Separation of Concerns | PASS | 5 focused Stimulus controllers for DOM-only concerns. Server handles all validation/persistence. |
| VII. Simplicity & YAGNI | PASS | No abstractions beyond what's needed. Templates as a hash constant. No custom ordering system. |

## Project Structure

### Documentation (this feature)

```text
specs/002-todo-lists/
├── plan.md              # This file
├── research.md          # Phase 0 — research decisions
├── data-model.md        # Phase 1 — entity definitions
├── quickstart.md        # Phase 1 — setup instructions
├── contracts/
│   └── ui-contracts.md  # Phase 1 — routes, views, Stimulus controllers
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── todo_lists_controller.rb       # CRUD for TODO lists
├── models/
│   ├── todo_list.rb                   # List model (validations, templates, colors, scopes)
│   ├── todo_section.rb                # Section model (position ordering)
│   └── todo_item.rb                   # Item model (completion tracking)
├── views/
│   ├── layouts/
│   │   └── app.html.erb               # Authenticated app layout (top nav)
│   └── todo_lists/
│       ├── index.html.erb             # Listing / blank slate
│       ├── new.html.erb               # Create form
│       ├── edit.html.erb              # Edit form
│       ├── show.html.erb              # Detail view / empty list slate
│       ├── _form.html.erb             # Shared form partial
│       ├── _list_card.html.erb        # Card partial for grid
│       ├── _sidebar.html.erb          # Left sidebar navigation
│       └── _delete_confirmation.html.erb  # Delete modal partial
├── javascript/controllers/
│   ├── color_picker_controller.js     # Color swatch selection
│   ├── icon_picker_controller.js      # Icon grid selection
│   ├── template_picker_controller.js  # Template card selection
│   ├── delete_confirmation_controller.js  # Modal open/close
│   └── list_search_controller.js      # Sidebar search filtering
└── assets/stylesheets/
    └── todo_lists.css                 # All feature styles

config/
└── routes.rb                          # Add: resources :todo_lists, path: "lists"

db/migrate/
├── YYYYMMDDHHMMSS_create_todo_lists.rb
├── YYYYMMDDHHMMSS_create_todo_sections.rb
└── YYYYMMDDHHMMSS_create_todo_items.rb

test/
├── models/
│   ├── todo_list_test.rb
│   ├── todo_section_test.rb
│   └── todo_item_test.rb
├── controllers/
│   └── todo_lists_controller_test.rb
└── system/
    └── todo_lists_test.rb
```

**Structure Decision**: Standard Rails directory structure. All TODO list code lives within the existing `app/` tree following Rails conventions. No new top-level directories needed. One feature CSS file (`todo_lists.css`) keeps styles organized. A new `app` layout separates authenticated app screens from the existing `authentication` layout.

## Design Decisions

### D1: App Layout

A new `app.html.erb` layout provides the top navigation bar visible in all .pen app screens (Facere logo, search, notification bell, user avatar). This is distinct from the existing `authentication.html.erb` layout used for sign-in/sign-up flows. The sidebar is NOT part of the layout — it's a partial rendered only in list detail views.

### D2: Template Application

Templates are applied via `TodoList#apply_template!` called after create. Template definitions live as a `TEMPLATES` constant (frozen hash) on the model. The method is wrapped in a `transaction` block so template seeding is all-or-nothing — if any section or item fails to create, the entire template application rolls back. This keeps the logic simple, testable, and co-located with the model. If template logic grows beyond ~30 lines, extract to a `ListTemplateApplier` service object.

### D3: Color & Icon Storage

Colors are stored as string identifiers ("purple", "blue", etc.) mapped to CSS custom properties for rendering. Icons are stored as Font Awesome icon name strings. Both have model-level constants (`COLORS`, `ICONS`) for validation and view rendering.

### D4: Delete Confirmation

Uses a custom modal dialog controlled by a `delete-confirmation-controller` Stimulus controller. The dialog contains a standard Rails `button_to` with `method: :delete` for the actual deletion. This keeps the server interaction in standard Rails while the UI uses an accessible modal pattern.

### D5: Root Route Update

Update `root` from `sessions#new` to `todo_lists#index`. The `require_authentication` before_action on `TodoListsController` will redirect unauthenticated users to sign-in automatically, so the root route correctly serves both authenticated and unauthenticated users.

### D6: Visual Reference Screens

The following screens from `initial-screens.pen` serve as the source of truth for UI/UX:

| Screen | Node ID | Purpose |
|--------|---------|---------|
| TODO Lists Overview - Blank Slate | `shnKl` | Empty state when user has no lists |
| TODO Lists Overview | `irMfg` | Grid of list cards with progress |
| Create New List | `nl3Mt` | Form with name/icon/color/description/template |
| Create New List - Error State | `Pngey` | Validation error display |
| New List Created - Detail View | `9oNUs` | Empty list after creation with success toast |
| TODO List Detail | `YLHU2` | Sidebar + sections with items |
| Delete Confirmation Modal | `FGDgb` | Centered modal with cancel/delete |
| Mobile - TODO Lists | `Pm5en` | Mobile card list layout |
| Mobile - TODO List Detail | `OBjvS` | Mobile item list with sections |
| Edit List | `xdB6f` | Edit form with disabled template picker (added) |
| Mobile - Blank Slate | `YQk5I` | Mobile empty state (added) |
| Mobile - Create New List | `amjUz` | Mobile create form (added) |
| Mobile - Delete Confirmation | `qTvHZ` | Mobile delete modal (added) |

### D7: UI Component Approach

Standard HTML elements with CSS styling and Font Awesome Pro icons via `<i>` tags:

| Element | Usage | Notes |
|---------|-------|-------|
| `<input>` | List name field | Styled with CSS for rounded corners and sizing. |
| `<button>` | All buttons (action, icon picker, template picker) | For icon-only buttons, place `<i>` tag with Font Awesome class inside. |
| `<i class="fa-thin fa-*">` | Icons everywhere | Font Awesome thin style for list items, solid for actions. |
| Custom modal dialog | Delete confirmation modal | Controlled via Stimulus controller. |

### D8: Error Banner (Custom HTML)

The `.pen` design specifies a custom error banner with exact padding (14px 18px), corner radius (16px), background (#FEE2E2), text color (#991B1B), triangle-alert icon (`<i class="fa-thin fa-triangle-exclamation"></i>`), and X close button. Custom HTML is used to match the design precisely.

### D9: List Card Design Tokens

The `.pen` design for list cards differs significantly from a typical card pattern:

| Property | Design Value | Common Default |
|----------|-------------|----------------|
| Background | `#F4F4F5` (zinc-100) | white |
| Border | 4px left-only colored accent stripe | 1px border all around |
| Corner radius | 24px | 12-16px |
| Layout | Flexbox column with 16px gap | margin-based spacing |
| Card structure | Drag handle → emoji circle (44x44, tinted bg) → title (17px) | Simple icon + title |
| Progress bar | 6px height, fully rounded (100px radius), zinc-200 bg | 4px, small radius |
| Meta layout | Percentage below progress bar; items + updated time on separate bottom row | All on one line |

### D10: Form Card Width Adjustment

The `.pen` design shows 5 color swatches at 620px card width. The app has 6 colors, so the form card was widened to 660px. Icon picker buttons are 40x40 (not 44x44) and color swatches are 26x26 (not 32 or 44) to fit within containers. Both containers have zinc-100 background fill with 16px corner radius.

### D11: Security — Authorization via Query Scoping

All controller actions scope queries through `Current.user.todo_lists`, which provides authorization at the database query level. This means accessing another user's list returns `ActiveRecord::RecordNotFound` → 404, not 403. This is intentional: returning 404 avoids revealing the existence of resources. Strong params exclude `user_id` from the whitelist, preventing parameter injection on create.

**Test coverage** (180 tests total, 493 assertions):
- Authentication required for all 7 actions (index, show, new, create, edit, update, destroy)
- Authorization isolation for index (no cross-user data), show, edit, update, destroy
- Parameter injection test (user_id ignored on create)
- Case-insensitive DB constraint test (bypasses model validation to verify index)

### D12: HTML Validity — No Nested Interactive Elements

Copilot flagged `<button>` inside `<a>` in the list card partial. This is invalid HTML per the spec and causes accessibility/click-handling issues. The card was restructured: wrapper is a `<div>`, the title and body are separate `<a>` links, and the menu button is a sibling — never nested inside a link.

### D13: N+1 Query Prevention

Controller actions now eager-load associations to prevent N+1 queries in views:
- `index`: `.includes(:todo_items)` for card rendering (completion %, item count)
- `show`: `.includes(:todo_items)` for sidebar, `@sections.includes(:todo_items)` for detail view
- `completion_percentage` uses in-memory collection when `todo_items` is already loaded
- Views use `.size` (reads loaded collection) instead of `.count` (forces SQL COUNT)
- `@unsectioned_items` is computed in the controller, not the view

### D14: Stimulus Event Binding on Custom Elements

All Stimulus actions on buttons should use explicit event syntax: `data-action="click->controller#method"` for consistency and clarity.

### D15: Case-Insensitive Database Constraint

SQLite's default unique index on `[user_id, name]` is case-sensitive. A separate migration adds `CREATE UNIQUE INDEX ... ON todo_lists(user_id, lower(name))` to prevent race-condition duplicates (e.g., "Groceries" vs "groceries") that bypass model validation.

### D16: System Tests

Standard Capybara interactions work with native HTML elements (`fill_in`, `click_button`). Key testing patterns:
- Use `find()` to wait for element presence before interacting
- Never use top-level `await` in `execute_script` — runs as classic script, not ES module
- Never use `sleep` — use Capybara's built-in waiting (`find`, `assert_text wait:`)

### D17: CI — Active Record Encryption Keys

2FA tests require Active Record encryption (`encrypts :otp_secret`). In CI, `RAILS_MASTER_KEY` must be set as a GitHub secret to decrypt credentials. As a fallback, deterministic test keys are configured in `config/environments/test.rb` so tests can run without the master key.

## Complexity Tracking

> No constitution violations detected. All design decisions align with core principles.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    | —          | —                                   |
