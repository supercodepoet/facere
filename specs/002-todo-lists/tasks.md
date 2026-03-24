# Tasks: TODO List Management

**Input**: Design documents from `/specs/002-todo-lists/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/ui-contracts.md

**Tests**: Included per constitution requirement — "All new features MUST include test coverage using Minitest; system tests for critical user flows"

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Visual Reference

All UI implementation should reference `designs/initial-screens.pen` as source of truth. Key screen node IDs:

| Screen | Node ID | Used By |
|--------|---------|---------|
| TODO Lists Overview - Blank Slate | `shnKl` | US1 |
| TODO Lists Overview | `irMfg` | US1 |
| Create New List | `nl3Mt` | US2 |
| Create New List - Error State | `Pngey` | US2 |
| New List Created - Detail View | `9oNUs` | US3 |
| TODO List Detail | `YLHU2` | US3 |
| Edit List | `xdB6f` | US4 |
| Delete Confirmation Modal | `FGDgb` | US5 |
| Mobile - TODO Lists | `Pm5en` | US1 |
| Mobile - Blank Slate | `YQk5I` | US1 |
| Mobile - TODO List Detail | `OBjvS` | US3 |
| Mobile - Create New List | `amjUz` | US2 |
| Mobile - Delete Confirmation | `qTvHZ` | US5 |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization — routes, layout, CSS foundation, database migrations

- [x] T001 Add resourceful routes for todo_lists with path "lists" and update root route to `todo_lists#index` in `config/routes.rb`
- [x] T002 Create the authenticated app layout with top navigation bar (Facere logo, search, notification bell, user avatar) in `app/views/layouts/app.html.erb` — reference the nav bar from .pen screen `irMfg` (node `3plPT`)
- [x] T003 [P] Create the base CSS file with color custom properties (`--list-color-purple` through `--list-color-orange`), font imports, and layout foundation in `app/assets/stylesheets/todo_lists.css`
- [x] T004 [P] Create migration for `todo_lists` table (user_id, name, color, icon, description, template, timestamps) with indexes per data-model.md in `db/migrate/YYYYMMDDHHMMSS_create_todo_lists.rb`
- [x] T005 [P] Create migration for `todo_sections` table (todo_list_id, name, position, timestamps) with index in `db/migrate/YYYYMMDDHHMMSS_create_todo_sections.rb`
- [x] T006 [P] Create migration for `todo_items` table (todo_list_id, todo_section_id, name, completed, position, timestamps) with indexes in `db/migrate/YYYYMMDDHHMMSS_create_todo_items.rb`
- [x] T007 Run `bin/rails db:migrate` to apply all migrations

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and controller skeleton that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 Create `TodoList` model with COLORS, ICONS, TEMPLATES constants, validations (name: presence/length/uniqueness, color: presence/inclusion, template: presence/inclusion, description: length), `recently_updated` scope, `belongs_to :user`, `has_many :todo_sections`/`:todo_items` (dependent: :destroy), and `apply_template!` method in `app/models/todo_list.rb`
- [x] T009 [P] Create `TodoSection` model with validations (name: presence/length, position: numericality), `belongs_to :todo_list`, `has_many :todo_items` (dependent: :destroy), default scope ordered by position in `app/models/todo_section.rb`
- [x] T010 [P] Create `TodoItem` model with validations (name: presence/length, position: numericality), `belongs_to :todo_list`, `belongs_to :todo_section` (optional: true), default scope ordered by position in `app/models/todo_item.rb`
- [x] T011 Add `has_many :todo_lists, dependent: :destroy` to the existing User model in `app/models/user.rb`
- [x] T012 Create `TodoListsController` skeleton with `layout "app"`, `before_action :require_authentication`, private `set_todo_list` and `todo_list_params` methods, scoping all queries to `Current.user.todo_lists` in `app/controllers/todo_lists_controller.rb`
- [x] T013 [P] Create TodoList model test with validations (name presence, uniqueness case-insensitive, length), color inclusion, template inclusion, `apply_template!` for all 4 templates in `test/models/todo_list_test.rb`
- [x] T014 [P] Create TodoSection model test with validations in `test/models/todo_section_test.rb`
- [x] T015 [P] Create TodoItem model test with validations in `test/models/todo_item_test.rb`

**Checkpoint**: Foundation ready — models validated, controller scaffolded, user story implementation can begin

---

## Phase 3: User Story 1 — View TODO Lists (Priority: P1) 🎯 MVP

**Goal**: Users see a blank slate when they have no lists, or a grid of list cards when they have lists. Entry point for the entire feature.

**Independent Test**: Navigate to `/lists` and verify blank slate (no lists) or card grid (has lists) displays correctly.

### Tests for User Story 1

- [x] T016 [P] [US1] Write controller tests for `index` action — blank slate when no lists, listing when lists exist, requires authentication, orders by most recently updated in `test/controllers/todo_lists_controller_test.rb`

### Implementation for User Story 1

- [x] T017 [US1] Implement `index` action in `TodoListsController` — load `Current.user.todo_lists.recently_updated`, render index view in `app/controllers/todo_lists_controller.rb`
- [x] T018 [US1] Create `todo_lists/index.html.erb` with conditional rendering: blank slate (illustration, heading "Your lists are waiting!", "Create My First List" CTA button, feature highlights) when no lists, or grid layout with list cards and "+ New List" button when lists exist — reference .pen screens `shnKl` and `irMfg` in `app/views/todo_lists/index.html.erb`
- [x] T019 [P] [US1] Create `_list_card.html.erb` partial showing list name, color bar, completion percentage, item count, "updated X ago" timestamp, and overflow menu — reference .pen screen `irMfg` card design in `app/views/todo_lists/_list_card.html.erb`
- [x] T020 [US1] Add CSS styles for blank slate (centered illustration, heading, CTA button, feature highlights), list card grid (responsive 3-column desktop, single column mobile), and list card component (color bar, progress, metadata) in `app/assets/stylesheets/todo_lists.css`

**Checkpoint**: User Story 1 complete — users can see blank slate or their lists at `/lists`

---

## Phase 4: User Story 2 — Create a New TODO List (Priority: P1)

**Goal**: Users can create a new list with name, color, icon, description, and template. Form validates required fields and enforces unique names. Non-blank templates seed sections and items.

**Independent Test**: Navigate to `/lists/new`, fill in form, submit, and verify list is created with correct attributes and template content.

### Tests for User Story 2

- [x] T021 [P] [US2] Write controller tests for `new` and `create` actions — renders form, creates list with valid params, rejects missing name, rejects duplicate name (case-insensitive), applies template on create, redirects to show on success, re-renders form with errors on failure in `test/controllers/todo_lists_controller_test.rb`

### Implementation for User Story 2

- [x] T022 [P] [US2] Create `color_picker_controller.js` Stimulus controller — manages color swatch selection, highlights active swatch, sets hidden form field value, pre-selects first color on connect in `app/javascript/controllers/color_picker_controller.js`
- [x] T023 [P] [US2] Create `icon_picker_controller.js` Stimulus controller — manages icon grid selection, highlights active icon, sets hidden form field value, allows deselection (click active icon to clear) in `app/javascript/controllers/icon_picker_controller.js`
- [x] T024 [P] [US2] Create `template_picker_controller.js` Stimulus controller — manages template card selection, highlights active card, sets hidden form field value, pre-selects "Blank" on connect, prevents deselection in `app/javascript/controllers/template_picker_controller.js`
- [x] T025 [US2] Create shared `_form.html.erb` partial with List Name (`<input>`), Icon picker (grid of icon buttons with Font Awesome icons and Stimulus), Color picker (swatches with Stimulus), Description (`<textarea>`, optional label), Template picker (Blank/Project/Weekly/Shopping cards with Stimulus), validation error rendering — accepts `todo_list` object and `editing` boolean to disable template picker — reference .pen screens `nl3Mt` and `Pngey` in `app/views/todo_lists/_form.html.erb`
- [x] T026 [US2] Create `todo_lists/new.html.erb` rendering the form partial inside a centered card with heading "Create a new list", subtitle, Cancel link and "Create List" button — reference .pen screen `nl3Mt` in `app/views/todo_lists/new.html.erb`
- [x] T027 [US2] Implement `new` and `create` actions in `TodoListsController` — `new` builds blank `TodoList` with default color/template, `create` saves and calls `apply_template!`, redirects to show with flash notice on success, re-renders new with flash alert on failure in `app/controllers/todo_lists_controller.rb`
- [x] T028 [US2] Add CSS styles for the create/edit form card (centered layout, field spacing), color swatches (circular, active state ring), icon picker grid (square buttons, active state), template cards (bordered, icon, label, active state), validation error styles (red border, error text, top callout) in `app/assets/stylesheets/todo_lists.css`

**Checkpoint**: User Story 2 complete — users can create lists from `/lists/new` with all field types and templates

---

## Phase 5: User Story 3 — View Empty TODO List (Priority: P2)

**Goal**: After creating a list (or navigating to an empty list), users see a detail view with sidebar navigation and a blank slate prompting them to add items.

**Independent Test**: Create a list via US2, verify redirect to show page with sidebar, list header, and "Your list is ready!" blank slate.

### Tests for User Story 3

- [x] T029 [P] [US3] Write controller tests for `show` action — renders show view, displays list details, shows blank slate for empty list, scopes to current user's lists only, returns 404 for other user's list in `test/controllers/todo_lists_controller_test.rb`

### Implementation for User Story 3

- [x] T030 [P] [US3] Create `list_search_controller.js` Stimulus controller — filters sidebar list items by search input text, shows/hides items based on name match in `app/javascript/controllers/list_search_controller.js`
- [x] T031 [US3] Create `_sidebar.html.erb` partial with search input, "MY LISTS" header, list of user's TODO lists as links with colored dots and item counts, active list highlighted, "+ New List" button at bottom — reference .pen screen `YLHU2` sidebar (node `RIqC6`) in `app/views/todo_lists/_sidebar.html.erb`
- [x] T032 [US3] Create `todo_lists/show.html.erb` with two-column layout: sidebar partial on left, main content area on right with list header (back arrow, list name, edit pencil icon), and conditional rendering — empty state ("Your list is ready!" illustration, "Add First Item" and "Add Section" buttons) or sections/items display — reference .pen screens `9oNUs` and `YLHU2` in `app/views/todo_lists/show.html.erb`
- [x] T033 [US3] Implement `show` action in `TodoListsController` — find list by id scoped to current user, load sections with items for display, set sidebar lists in `app/controllers/todo_lists_controller.rb`
- [x] T034 [US3] Add CSS styles for sidebar (fixed width, scrollable list, active highlight, colored dots, search input), show view two-column layout (sidebar + main content), list header (back arrow, title, edit icon), and empty list blank slate (illustration, buttons) in `app/assets/stylesheets/todo_lists.css`

**Checkpoint**: User Story 3 complete — users can see list detail view with sidebar and empty state

---

## Phase 6: User Story 4 — Edit a TODO List (Priority: P2)

**Goal**: Users can edit an existing list's name, color, icon, and description. Template is read-only. Same validation rules as creation.

**Independent Test**: Navigate to an existing list, click edit, modify fields, save, verify changes reflected.

### Tests for User Story 4

- [x] T035 [P] [US4] Write controller tests for `edit` and `update` actions — renders form with current values, updates with valid params, rejects duplicate name, rejects blank name, redirects to show on success, re-renders edit with errors on failure in `test/controllers/todo_lists_controller_test.rb`

### Implementation for User Story 4

- [x] T036 [US4] Create `todo_lists/edit.html.erb` rendering the shared form partial with `editing: true` (template picker disabled), heading "Edit list", subtitle "Update your list's name, icon, color, and description", Cancel link and "Save Changes" button — reference .pen screen `xdB6f` in `app/views/todo_lists/edit.html.erb`
- [x] T037 [US4] Implement `edit` and `update` actions in `TodoListsController` — `edit` finds and renders form, `update` saves permitted params (excluding template), redirects to show with flash notice on success, re-renders edit with flash alert on failure in `app/controllers/todo_lists_controller.rb`
- [x] T038 [US4] Add edit link/button to the list show view header (pencil icon next to list name) linking to edit path in `app/views/todo_lists/show.html.erb`

**Checkpoint**: User Story 4 complete — users can edit list details with all validation rules

---

## Phase 7: User Story 5 — Delete a TODO List (Priority: P3)

**Goal**: Users can delete a list after confirming via a modal dialog. All sections and items are permanently removed. User returns to listing (or blank slate if last list).

**Independent Test**: Navigate to a list, trigger delete, confirm in modal, verify list removed and redirected to index.

### Tests for User Story 5

- [x] T039 [P] [US5] Write controller tests for `destroy` action — deletes list and all associated sections/items, redirects to index with flash notice, scopes to current user in `test/controllers/todo_lists_controller_test.rb`

### Implementation for User Story 5

- [x] T040 [P] [US5] Create `delete_confirmation_controller.js` Stimulus controller — opens modal dialog on trigger click, closes on cancel button click, manages modal visibility in `app/javascript/controllers/delete_confirmation_controller.js`
- [x] T041 [US5] Create `_delete_confirmation.html.erb` partial with modal dialog containing trash icon in pink circle, "Delete this list?" heading, warning text, Cancel button and red Delete button (`button_to` with `method: :delete`) — reference .pen screen `FGDgb` in `app/views/todo_lists/_delete_confirmation.html.erb`
- [x] T042 [US5] Implement `destroy` action in `TodoListsController` — find list, destroy (cascades to sections/items), redirect to index with flash notice in `app/controllers/todo_lists_controller.rb`
- [x] T043 [US5] Add delete trigger button and render delete confirmation partial in the list show view in `app/views/todo_lists/show.html.erb`
- [x] T044 [US5] Add CSS styles for delete confirmation modal (centered overlay, card styling, icon circle, button row, red delete button) in `app/assets/stylesheets/todo_lists.css`

**Checkpoint**: User Story 5 complete — users can delete lists with confirmation

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: System tests, responsive design, animations, CI compliance

- [x] T045 [P] Write system tests covering full user flows: sign in → view blank slate → create list → view list → edit list → delete list in `test/system/todo_lists_test.rb`
- [x] T046 [P] Add responsive CSS for mobile layouts — single-column card grid, full-width sidebar overlay, compact form, mobile nav adjustments — reference .pen mobile screens `Pm5en`, `YQk5I`, `OBjvS`, `amjUz`, `qTvHZ` in `app/assets/stylesheets/todo_lists.css`
- [x] T047 [P] Add CSS transitions and micro-animations — card hover lift effect, color swatch pulse on select, template card scale on select, blank slate fade-in, toast slide-in, modal backdrop fade — in `app/assets/stylesheets/todo_lists.css`
- [x] T048 Add shared `_flash_messages.html.erb` rendering to app layout (or verify existing partial works with app layout) for success/error toasts in `app/views/layouts/app.html.erb`
- [x] T049 Run `bin/rubocop` and fix any offenses across all new Ruby files
- [x] T050 Run `bin/brakeman --no-pager` and fix any security warnings
- [x] T051 [P] Run `bin/bundler-audit` and resolve any dependency advisories
- [x] T052 [P] Run `bin/importmap audit` and resolve any JS dependency vulnerabilities
- [x] T053 Run `bin/rails test` and `bin/rails test:system` — verify zero failures
- [x] T054 Verify all acceptance scenarios from spec.md pass manually

---

## Phase 9: Design Review & Security Hardening

**Purpose**: Validate implementation against `.pen` visual reference, fix design gaps, and add comprehensive security test coverage.

### Design Review — List Cards (US1)

- [x] T055 [US1] Fix list card styling to match .pen design: background zinc-100 (#F4F4F5), border-radius 24px, 4px left-only colored accent stripe, card layout with flexbox column gap 16px in `app/assets/stylesheets/todo_lists.css`
- [x] T056 [US1] Add drag handle icon (`grip-dots-vertical`), emoji circle (44x44, tinted background), and restructure card header with 12px gap in `app/views/todo_lists/_list_card.html.erb`
- [x] T057 [US1] Fix card title font-size (16→17px), progress bar (4→6px height, 2→100px radius, zinc-100→zinc-200 bg), and card meta layout (percentage below progress bar, items+updated on separate bottom row) in CSS and partial
- [x] T058 [US1] Add per-color CSS classes for card accent stripe, emoji circle tint, and progress bar fill across all 6 colors (purple, blue, teal, green, pink, orange) in `app/assets/stylesheets/todo_lists.css`
- [x] T059 [US1] Fix "New List" button sizing (height 44px, padding 0 24px, gap 8px, font 15px) and "Create New List" card (border-radius 24px, min-height 186px, plus icon in 48px circle) in CSS
- [x] T060 [US1] Fix logo text font-size (20→22px) to match .pen nav bar in `app/assets/stylesheets/todo_lists.css`

### Design Review — Create/Edit Form (US2, US4)

- [x] T061 [US2] Create custom error banner matching .pen design: #FEE2E2 bg, 16px radius, 14px 18px padding, triangle-exclamation icon (`<i class="fa-thin fa-triangle-exclamation"></i>`), #991B1B text, close button in `app/views/todo_lists/new.html.erb` and `edit.html.erb`
- [x] T062 [US2] Fix input error state: label turns red (#EF4444), input background #FEF2F2 with 2px red border, error text gap 6px with 14px icon in `app/assets/stylesheets/todo_lists.css`
- [x] T063 [US2] Fix form element corner radii: input 16px (via `pill` attribute), textarea 16px, form buttons 16px in CSS
- [x] T064 [US2] Fix form button styling: Cancel (1.5px border zinc-300, 15px font), Create (purple gradient, sparkles icon, box-shadow) in CSS

### Component Corrections

- [x] T065 Ensure all icon-only buttons use `<button>` with `<i>` Font Awesome icon tags in `_form.html.erb`, `new.html.erb`, `edit.html.erb`
- [x] T066 Verify all button and form element attributes are correct across all view files
- [x] T067 Add rounded corner styling to inputs; use CSS custom properties for sizing in `app/assets/stylesheets/todo_lists.css`
- [x] T068 Style action buttons (Cancel, Create List, Save Changes) with proper CSS classes in `new.html.erb` and `edit.html.erb`
- [x] T069 Style icon picker buttons (icon-only, 40x40) and template picker buttons in `_form.html.erb`

### Design Review — Sizing & Spacing

- [x] T070 Fix header subtitle font-size (14→15px, add line-height 1.5), textarea font-size (14→15px), label optional style (remove italic, set 12px) in CSS
- [x] T071 Fix color section width (flex:1 → 240px fixed), add container backgrounds (zinc-100, radius 16px) to icon picker (padding 10 12) and color picker (padding 14) in CSS
- [x] T072 Fix template picker: gap 12→10px, card padding 20px 16px → 14px 12px, internal gap 10→6px, background zinc-100 (no border), active outline style in CSS
- [x] T073 Fix icon picker buttons (44→40px) and color swatches (44→26px) to match .pen design; widen form card (620→660px) to accommodate 6 colors on one row in CSS
- [x] T074 Change template cards to `size="small"` and action buttons to `size="medium"` to match .pen text proportions in view files and CSS

### Security Test Coverage (US6)

- [x] T075 [P] [US6] Add authentication tests for all 7 actions (show, new, create, edit, update, destroy — index already tested) — verify unauthenticated users are redirected in `test/controllers/todo_lists_controller_test.rb`
- [x] T076 [P] [US6] Add authorization test: edit returns 404 for another user's list in `test/controllers/todo_lists_controller_test.rb`
- [x] T077 [P] [US6] Add authorization test: update returns 404 for another user's list and data is unchanged in `test/controllers/todo_lists_controller_test.rb`
- [x] T078 [P] [US6] Add index isolation test: user does not see other user's lists in `test/controllers/todo_lists_controller_test.rb`
- [x] T079 [P] [US6] Add parameter injection test: create ignores `user_id` param and assigns to current user in `test/controllers/todo_lists_controller_test.rb`

**Checkpoint**: 160 tests, 434 assertions, 0 failures — all design, component, and security issues resolved

---

## Phase 10: Copilot Code Review Fixes

**Purpose**: Address all 22 Copilot code review comments on PR #7 — HTML validity, N+1 queries, Stimulus event binding, transaction safety, system test reliability, DB constraints, CI config, and doc typos.

### HTML & Accessibility

- [x] T080 [US1] Restructure list card partial: remove `<button>` from inside `<a>`, make wrapper a `<div>`, title and body as separate links, menu button as sibling in `app/views/todo_lists/_list_card.html.erb`

### Performance (N+1 Queries)

- [x] T081 Add `.includes(:todo_items)` to index and show controller actions for eager loading in `app/controllers/todo_lists_controller.rb`
- [x] T082 Move `@todo_list.todo_items.where(todo_section_id: nil)` from view to `@unsectioned_items` in controller
- [x] T083 Change `.count` to `.size` in sidebar (`_sidebar.html.erb`) and show view (`show.html.erb`) for eager-loaded associations
- [x] T084 Memoize `completion_percentage` in local variable in `_list_card.html.erb`; update model method to use in-memory collection when loaded in `app/models/todo_list.rb`

### Stimulus Event Binding

- [x] T085 Add explicit `click->` prefix to all Stimulus actions on buttons (icon picker, template picker, color swatch, delete trigger) in `_form.html.erb` and `show.html.erb`
- [x] T086 Fix delete confirmation cancel button: replace broken Stimulus action (controller on different element) with inline `onclick` in `_delete_confirmation.html.erb`

### Data Integrity

- [x] T087 Wrap `apply_template!` in `transaction` block for all-or-nothing template seeding in `app/models/todo_list.rb`
- [x] T088 Add case-insensitive unique index migration `lower(name)` scoped by `user_id` in `db/migrate/20260321180000_add_case_insensitive_unique_index_to_todo_lists.rb`
- [x] T089 Add model test verifying DB-level case-insensitive constraint (bypasses model validation) in `test/models/todo_list_test.rb`

### Slot Fix

- [x] T090 Fix sidebar search icon placement in `_sidebar.html.erb`

### System Test Reliability

- [x] T091 Remove top-level `await` from `execute_script` calls (runs as classic script, not ES module); use Capybara `find()` waits instead in `test/system/todo_lists_test.rb`
- [x] T092 Remove `sleep 0.3` from sign-in setup; use `assert_no_text` with Capybara wait instead in `test/system/todo_lists_test.rb`

### CI Configuration

- [x] T093 Add deterministic Active Record encryption keys in `config/environments/test.rb` for CI without `RAILS_MASTER_KEY`
- [x] T094 Uncomment `RAILS_MASTER_KEY` in `.github/workflows/ci.yml` for both test and system-test jobs
- [x] T095 Set `RAILS_MASTER_KEY` as GitHub secret via `gh secret set`

### Documentation

- [x] T096 Update UI contracts: custom `.form-error-banner` in `specs/002-todo-lists/contracts/ui-contracts.md`
- [x] T097 Fix typos: "expierence"→"experience", "Fill free"→"Feel free", "refence"→"reference" in `prompts/specs/002/plan.md`
- [x] T098 Fix grammar: "screens to managing"→"screens for managing", "all out TODO"→"all our TODO" in `prompts/specs/002/spec.md`

**Checkpoint**: 180 tests, 493 assertions, 0 failures — all Copilot review comments resolved, CI green

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T007 migrations applied) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Depends on Foundational phase completion (can run parallel with US1)
- **User Story 3 (Phase 5)**: Depends on Foundational phase completion (benefits from US2 for create→show flow)
- **User Story 4 (Phase 6)**: Depends on US2 completion (reuses `_form.html.erb` partial)
- **User Story 5 (Phase 7)**: Depends on US3 completion (delete trigger lives in show view)
- **Polish (Phase 8)**: Depends on all user stories being complete
- **Design Review & Security (Phase 9)**: Depends on Phase 8 completion. Validates implementation against .pen visual reference and hardens security test coverage.
- **Copilot Code Review (Phase 10)**: Depends on Phase 9 completion. Addresses PR review findings — HTML validity, N+1 queries, Stimulus binding, transaction safety, DB constraints, system test reliability, CI config.

### User Story Dependencies

```
Phase 1: Setup
    ↓
Phase 2: Foundational
    ↓
    ├── Phase 3: US1 - View Lists (P1) ──────┐
    │                                         │
    ├── Phase 4: US2 - Create List (P1) ──┐   │
    │                                     │   │
    │   Phase 5: US3 - View Empty (P2) ◄──┤   │
    │                                     │   │
    │   Phase 6: US4 - Edit List (P2) ◄───┘   │
    │                                         │
    │   Phase 7: US5 - Delete List (P3) ◄─────┘ (needs show view from US3)
    │
    ↓
Phase 8: Polish
```

### Within Each User Story

- Tests written first (marked [P] where possible)
- Stimulus controllers (marked [P] — independent JS files)
- View partials before page templates
- Controller actions after views are ready
- CSS additions after markup is finalized

### Parallel Opportunities

**Phase 1** — T003, T004, T005, T006 can all run in parallel (different files)

**Phase 2** — T009, T010 in parallel (different models); T013, T014, T015 in parallel (different test files)

**Phase 3 (US1)** — T016 (test) and T019 (partial) can run in parallel

**Phase 4 (US2)** — T021 (test), T022, T023, T024 (all 3 Stimulus controllers) can run in parallel

**Phase 5 (US3)** — T029 (test) and T030 (Stimulus) can run in parallel

**Phase 8** — T045, T046, T047 can all run in parallel

---

## Parallel Example: User Story 2

```bash
# Launch in parallel (independent files):
Task: T021 "Controller tests for new/create in test/controllers/todo_lists_controller_test.rb"
Task: T022 "Color picker Stimulus controller in app/javascript/controllers/color_picker_controller.js"
Task: T023 "Icon picker Stimulus controller in app/javascript/controllers/icon_picker_controller.js"
Task: T024 "Template picker Stimulus controller in app/javascript/controllers/template_picker_controller.js"

# Then sequentially (depends on above):
Task: T025 "Shared form partial in app/views/todo_lists/_form.html.erb"
Task: T026 "New list page in app/views/todo_lists/new.html.erb"
Task: T027 "Controller actions for new/create in app/controllers/todo_lists_controller.rb"
Task: T028 "Form CSS styles in app/assets/stylesheets/todo_lists.css"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup (routes, layout, CSS, migrations)
2. Complete Phase 2: Foundational (models, controller skeleton, model tests)
3. Complete Phase 3: User Story 1 — View Lists (blank slate + listing)
4. Complete Phase 4: User Story 2 — Create List (form + templates)
5. **STOP and VALIDATE**: Users can view, create, and browse lists
6. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (View Lists) → Users see blank slate → partial value
3. Add US2 (Create List) → Users can create and view lists → **MVP!**
4. Add US3 (View Empty List) → Detail view with sidebar → richer navigation
5. Add US4 (Edit List) → Full CRUD minus delete → management capability
6. Add US5 (Delete List) → Complete CRUD → feature complete
7. Polish → Responsive, animations, CI green → production ready

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- All UI implementation references `designs/initial-screens.pen` — use `get_screenshot` to validate against .pen screens
- Standard HTML elements with CSS styling. Font Awesome Pro icons via `<i>` tags (e.g., `<i class="fa-thin fa-icon-name"></i>`). Custom error banner for validation errors.
- Stimulus controllers handle DOM interaction only — server handles all validation/persistence via Turbo
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
