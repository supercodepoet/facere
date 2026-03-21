# Implementation Plan: TODO List Management

**Branch**: `002-todo-lists` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-todo-lists/spec.md`

## Summary

Implement full CRUD for TODO Lists within the existing Rails 8.1 application. Users can view their lists (with blank slate for empty state), create new lists with name/color/icon/description/template, edit list details, and delete lists with confirmation. The UI follows the `initial-screens.pen` visual reference using Web Awesome Pro components, Font Awesome Pro icons, and Hotwire (Turbo + Stimulus) for all interactivity. Templates (Blank, Project, Weekly, Shopping) pre-populate lists with named sections and starter items on creation.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive + Stimulus), Web Awesome Pro (CDN kit), Font Awesome Pro (CDN kit), bcrypt (existing)
**Storage**: SQLite (all environments)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web (responsive — desktop + mobile)
**Project Type**: Web application
**Performance Goals**: Standard web app — pages render in <1s, form submissions in <500ms
**Constraints**: Server-rendered HTML via Turbo, no SPA frameworks, Web Awesome Pro for all components
**Scale/Scope**: 7 screens (4 desktop + 2 mobile + 1 modal), 3 new database tables, 1 controller, 5 Stimulus controllers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Standard Rails MVC + resourceful routes + Hotwire. No external JS frameworks. |
| II. Library-First | PASS | Web Awesome Pro for components, Font Awesome Pro for icons. No custom UI primitives. |
| III. Joyful User Experience | PASS | Following .pen visual reference with micro-interactions, branded illustrations, polished blank slates. |
| IV. Clean Architecture & DDD | PASS | Domain-specific naming (TodoList, TodoSection, TodoItem). Business logic in models. |
| V. Code Quality & Readability | PASS | Standard CRUD controller, focused models, isolated Stimulus controllers. |
| VI. Separation of Concerns | PASS | Stimulus for DOM (pickers, modals), Turbo for navigation, models for logic. |
| VII. Simplicity & YAGNI | PASS | Only building screens in spec. Template data as constants, not a separate system. |

### Post-Design Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | `resources :todo_lists` routing, standard controller actions, Turbo Drive navigation. |
| II. Library-First | PASS | `wa-dialog` for modal, `wa-input` (with `pill`), `wa-button` (with `slot="start"`/`appearance="outlined"`), `wa-icon` for form elements. Custom error banner replaced `wa-callout` to match .pen design exactly. |
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

Templates are applied via `TodoList#apply_template!` called after create. Template definitions live as a `TEMPLATES` constant (frozen hash) on the model. This keeps the logic simple, testable, and co-located with the model. If template logic grows beyond ~30 lines, extract to a `ListTemplateApplier` service object.

### D3: Color & Icon Storage

Colors are stored as string identifiers ("purple", "blue", etc.) mapped to CSS custom properties for rendering. Icons are stored as Font Awesome icon name strings. Both have model-level constants (`COLORS`, `ICONS`) for validation and view rendering.

### D4: Delete Confirmation

Uses `wa-dialog` (Web Awesome Pro's modal component) controlled by a `delete-confirmation-controller` Stimulus controller. The dialog contains a standard Rails `button_to` with `method: :delete` for the actual deletion. This keeps the server interaction in standard Rails while the UI uses Web Awesome Pro's accessible modal pattern.

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

### D7: Web Awesome Component Usage

Through design review and iteration, the following Web Awesome usage patterns were established:

| Component | Usage | Notes |
|-----------|-------|-------|
| `wa-input` | List name field | Use `pill` attribute for rounded corners. Style via CSS custom properties (`--wa-input-height-medium`, `--wa-input-spacing-medium`), NOT `::part(base)` padding overrides which clip placeholder text. |
| `wa-button` | All buttons (action, icon picker, template picker) | No `wa-icon-button` component exists. For icon-only buttons, place `<wa-icon>` in the default slot. |
| `wa-icon` | Icons everywhere | In `wa-button`, use `slot="start"` (not `slot="prefix"`). Standalone icons use `variant="thin"`. |
| `wa-dialog` | Delete confirmation modal | Controlled via Stimulus controller. |

**Key API corrections** (from [Web Awesome docs](https://webawesome.com/docs/components/button/)):
- Slots: `start`, `end` (default slot for label) — NOT `prefix`/`suffix`
- Appearance: `appearance="outlined"` — NOT boolean `outline` attribute
- Variants: `neutral`, `brand`, `success`, `warning`, `danger`
- No `wa-icon-button` component — use `wa-button` with icon in default slot

### D8: Error Banner (Custom vs wa-callout)

The `.pen` design specifies a custom error banner with exact padding (14px 18px), corner radius (16px), background (#FEE2E2), text color (#991B1B), triangle-alert icon, and X close button. `wa-callout` was initially used but replaced with custom HTML to match the design precisely. The close button uses `wa-button appearance="plain" size="small"`.

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

**Test coverage added** (159 tests total):
- Authentication required for all 7 actions (index, show, new, create, edit, update, destroy)
- Authorization isolation for index (no cross-user data), show, edit, update, destroy
- Parameter injection test (user_id ignored on create)

## Complexity Tracking

> No constitution violations detected. All design decisions align with core principles.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    | —          | —                                   |
