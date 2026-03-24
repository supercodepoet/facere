# Implementation Plan: TODO List Items Management

**Branch**: `003-todo-list-items` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-todo-list-items/spec.md`

## Summary

Implement full TODO item and section management within the existing Rails 8.1 application. Users can create items and sections inline (optimized for speed with Enter-to-save flow), reorder via drag-and-drop, toggle completion, view/edit rich item details (notes, checklist, due date, priority, tags, attachments), and manage items/sections via context menus (edit, move, copy, archive, delete). The UI follows `todo-list-item-screens.pen` using standard HTML elements styled with CSS, Font Awesome Pro icons (via `<i>` tags), and Hotwire (Turbo Streams + Stimulus) for all interactivity. ActionText with Trix provides rich text editing for item notes.

**Test coverage**: 223 tests, 556 assertions — all passing. Includes model validations/scopes/business logic, controller auth/authz/CRUD, and system tests for list creation/editing/deletion.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive + Turbo Streams + Turbo Frames + Stimulus), Font Awesome Pro (CDN kit), ActionText (Rails built-in, for notes), Active Storage (Rails built-in, for attachments)
**Storage**: SQLite (all environments)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web (responsive — desktop + mobile)
**Project Type**: Web application
**Performance Goals**: Standard web app — inline creation <200ms, drag-and-drop reorder <300ms, page transitions <1s
**Constraints**: Server-rendered HTML via Turbo, no SPA frameworks, Font Awesome Pro for all icons
**Scale/Scope**: 5 key screens (Adding First Item, Adding Section, List With Items & Sections, TODO List Detail, TODO Item Detail), 2 context menus, 1 drag-to-reorder interaction, 4 database migrations, 2 new controllers, ~10 Stimulus controllers, ~15 new/updated view partials

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Standard Rails MVC + nested resourceful routes + Turbo Streams for real-time updates + Stimulus for DOM. No external JS frameworks. |
| II. Library-First | PASS | Font Awesome Pro for icons, ActionText for rich text, Active Storage for file attachments. Standard HTML elements with CSS styling. |
| III. Joyful User Experience | PASS | Inline creation for speed, drag-and-drop with animations, context menus, micro-interactions (checkbox toggle animation, drag lift effect). Following .pen visual reference. |
| IV. Clean Architecture & DDD | PASS | Domain-specific naming (TodoItem, TodoSection, ChecklistItem). Business logic in models. Controllers orchestrate. Scoped queries via Current.user. |
| V. Code Quality & Readability | PASS | Focused controllers (<50 lines/action), isolated Stimulus controllers, CSS organized in feature file. |
| VI. Separation of Concerns | PASS | Stimulus for DOM interactions (drag, inline edit, context menus). Turbo for server communication. Models for business logic. |
| VII. Simplicity & YAGNI | PASS | Only building screens in spec. Assignees/Comments/Notify are single-user stubs. No team model. |

### Post-Design Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Nested `resources` routing, standard CRUD controllers, Turbo Streams for inline updates, Turbo Frames for partial page updates. ActionText for rich text. |
| II. Library-First | PASS | Custom HTML dropdown menus for context menus, modal dialogs for confirmations, tooltips for drag hints, standard `<input>` for inline creation, `<button>` with `<i>` Font Awesome icons for all buttons/icons. ActionText/Trix for notes. Active Storage for attachments. |
| III. Joyful User Experience | PASS | Inline creation with Enter-to-continue flow, smooth drag animations with purple border + rotation + shadow, context menus with hover states, completion checkbox animation, section collapse transitions. |
| IV. Clean Architecture & DDD | PASS | `TodoItem` encapsulates status/priority/due-date logic. `ChecklistItem` for sub-tasks. Scoped queries via `Current.user.todo_lists`. Eager loading for N+1 prevention. |
| V. Code Quality & Readability | PASS | Controllers focused on CRUD. Stimulus controllers isolated by concern (one per interaction pattern). CSS organized in single feature file extension. |
| VI. Separation of Concerns | PASS | ~10 focused Stimulus controllers for DOM-only concerns. Server handles all validation/persistence via Turbo. |
| VII. Simplicity & YAGNI | PASS | No abstractions beyond what's needed. Archive is a boolean flag. Tags are simple strings. Priority is an enum-like string field. |

## Project Structure

### Documentation (this feature)

```text
specs/003-todo-list-items/
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
│   ├── todo_lists_controller.rb       # Updated: show action enhancements
│   ├── todo_items_controller.rb       # NEW: CRUD + toggle + move + copy + reorder
│   └── todo_sections_controller.rb    # NEW: CRUD + move + reorder
├── models/
│   ├── todo_list.rb                   # Updated: associations
│   ├── todo_section.rb                # Updated: icon, archived, scopes
│   ├── todo_item.rb                   # Updated: status, due_date, priority, notes, archived, scopes
│   ├── checklist_item.rb              # NEW: sub-tasks for items
│   └── tag.rb                         # NEW: categorization labels
├── views/
│   ├── todo_lists/
│   │   ├── show.html.erb              # Major overhaul: inline creation, sections, drag-and-drop
│   │   ├── _section.html.erb          # NEW: section partial with header + items
│   │   ├── _todo_item.html.erb        # NEW: item row partial (checkbox, title, badges)
│   │   ├── _todo_item_completed.html.erb  # NEW: completed item variant
│   │   ├── _inline_item_input.html.erb    # NEW: inline creation input row
│   │   ├── _inline_section_input.html.erb # NEW: inline section creation
│   │   ├── _item_context_menu.html.erb    # NEW: dropdown menu for item actions
│   │   ├── _section_context_menu.html.erb # NEW: dropdown menu for section actions
│   │   ├── _quick_actions.html.erb        # NEW: assign/due/priority buttons
│   │   ├── _empty_section.html.erb        # NEW: empty section hint
│   │   └── _sidebar.html.erb             # Updated: item counts
│   └── todo_items/
│       ├── show.html.erb              # NEW: item detail page (two-column layout)
│       ├── _notes_section.html.erb    # NEW: ActionText notes with edit toggle
│       ├── _checklist_section.html.erb # NEW: checklist with progress
│       ├── _attachments_section.html.erb  # NEW: file cards grid
│       ├── _status_sidebar.html.erb   # NEW: right column metadata
│       └── _tags_card.html.erb        # NEW: tag pills
├── javascript/controllers/
│   ├── inline_item_controller.js      # NEW: inline item creation (Enter/Esc)
│   ├── inline_section_controller.js   # NEW: inline section creation + icon picker
│   ├── context_menu_controller.js     # NEW: dropdown menu trigger positioning
│   ├── drag_reorder_controller.js     # NEW: drag-and-drop with animations
│   ├── section_collapse_controller.js # NEW: expand/collapse sections
│   ├── item_checkbox_controller.js    # NEW: toggle completion via Turbo
│   ├── quick_actions_controller.js    # NEW: due date/priority/assign pickers
│   ├── notes_editor_controller.js     # NEW: toggle ActionText edit mode
│   ├── checklist_controller.js        # NEW: add/toggle/remove checklist items
│   └── tag_manager_controller.js      # NEW: add/remove tags
└── assets/stylesheets/
    └── todo_lists.css                 # Updated: extensive additions for items, sections, detail view

config/
└── routes.rb                          # Updated: nested item + section routes

db/migrate/
├── YYYYMMDDHHMMSS_add_fields_to_todo_items.rb      # status, due_date, priority, archived
├── YYYYMMDDHHMMSS_add_fields_to_todo_sections.rb   # icon, archived
├── YYYYMMDDHHMMSS_create_checklist_items.rb
└── YYYYMMDDHHMMSS_create_tags_and_item_tags.rb

test/
├── models/
│   ├── todo_item_test.rb              # Updated: new field validations, status transitions
│   ├── todo_section_test.rb           # Updated: icon, archive
│   ├── checklist_item_test.rb         # NEW
│   └── tag_test.rb                    # NEW
├── controllers/
│   ├── todo_items_controller_test.rb  # NEW: full CRUD + security tests
│   └── todo_sections_controller_test.rb # NEW: full CRUD + security tests
└── system/
    └── todo_items_test.rb             # NEW: inline creation, drag-and-drop, detail view
```

**Structure Decision**: Standard Rails directory structure. TODO item management extends the existing `todo_lists/` views and adds a new `todo_items/` controller and views. All new code follows Rails conventions. One feature CSS file (`todo_lists.css`) is extended rather than creating a new file, keeping styles co-located.

## Design Decisions

### D1: Fizzy Clarification — Use ActionText with Trix

The user referenced "Fizzy" as a rich text editor. Research found that Fizzy (`basecamp/fizzy`) is 37signals' Kanban project management tool, NOT an editor. The actual rich text editor successor to Trix is **Lexxy** (`basecamp/lexxy`), currently in beta (v0.9.0.beta). Given Lexxy's beta status and the user's instruction to "use standard Rails tools like ActionText," this plan uses **ActionText with Trix** (built into Rails 8.1). When Lexxy reaches stable release, it can replace Trix as a drop-in via `gem "lexxy"` + `bin/rails lexxy:install`.

### D2: UI Component Approach for Context Menus

Context menus use custom HTML dropdown menus with Stimulus controllers. Key patterns:

| Element | Usage | Notes |
|---------|-------|-------|
| Custom dropdown | Context menus for items and sections | Triggered by ellipsis button click. Uses click events for action dispatch. |
| Dropdown items | Menu actions (Edit, Move, Copy, Delete, etc.) | CSS danger class for destructive actions (Delete, Delete group). |
| Modal dialog | Delete confirmation, move/copy destination picker | Controlled via Stimulus. Click-outside to close. |
| Tooltip | Drag hint ("Click & hold to reorder") | Appears on hover over grip handle. |
| `<input>` | Inline item/section name input | CSS rounded corners. Keyboard hints below. |
| `<button>` | All action buttons (Add Item, Add Section, Mark Complete) | `<i>` Font Awesome icons inside. |
| `<i class="fa-thin fa-*">` | All icons throughout | Font Awesome thin style for list items. |

### D3: Inline Creation Architecture

Inline item creation uses a Stimulus controller (`inline_item_controller`) that:
1. Renders an active input row via Turbo Stream (appended to the target section or unsectioned area)
2. Listens for Enter (save via `fetch` POST → Turbo Stream response prepends new item)
3. Listens for Esc (removes the input row, no server call)
4. On successful save, the server responds with a Turbo Stream that replaces the input with the saved item AND appends a new empty input (Enter-to-continue flow)

Section creation follows the same pattern with an additional icon picker dropdown (custom dropdown with icon grid).

### D4: Drag-and-Drop Reordering

Drag-and-drop uses a Stimulus controller (`drag_reorder_controller`) with native HTML5 Drag and Drop API:
- `dragstart`: Adds purple border, rotation (-1deg), shadow to the dragged element. Shows tooltip hint.
- `dragover`: Highlights drop zones with an insertion indicator line.
- `drop`: Sends PATCH request to reorder endpoint with new position and optional new section_id.
- `dragend`: Removes all visual effects.

Server-side: The reorder endpoint receives `{ id, position, section_id }` and updates positions in a transaction. Uses `acts_as_list`-style position management (manual, no gem — positions are integers recalculated on reorder).

Animations: CSS transitions on `transform`, `opacity`, and `box-shadow` for smooth lift/drop effects. The dragged item gets `transform: rotate(-1deg)` and elevated shadow per the design.

### D5: Item Completion Toggle

Clicking the checkbox sends a PATCH request via Turbo Stream to `toggle` action. The response replaces the item partial, swapping between the normal and completed variants. CSS transitions handle the opacity fade and checkmark appearance animation.

### D6: TODO Item Detail — Two-Column Layout

The item detail page (`todo_items#show`) uses a two-column layout:
- **Left column** (flexible width): Item header (status/priority badges, title, metadata), Notes (ActionText), Checklist (inline add/toggle), Attachments (Active Storage with file cards), Comments (single-user, personal notes in threaded format)
- **Right column** (fixed ~280px): Status selector, Due Date, Tags, Actions (Mark Complete, Delete)

Each section is a Turbo Frame for independent updates without full page reload.

### D7: ActionText for Notes

Notes use ActionText (Rails built-in) which provides:
- Trix rich text editor (paragraphs, bullet lists, bold, italic, links)
- Content stored as `ActionText::RichText` (HTML in `action_text_rich_texts` table)
- File embeds via Active Storage (images inline in notes)
- Edit mode toggled by a Stimulus controller: view mode shows rendered HTML, edit mode shows Trix editor

Setup: `bin/rails action_text:install` + `has_rich_text :notes` on TodoItem model.

### D8: Checklist as Nested Resource

Checklist items are a simple model (`ChecklistItem`) belonging to `TodoItem`:
- Fields: `name`, `completed` (boolean), `position` (integer)
- Rendered inline in the item detail view
- Add/toggle/remove via Turbo Streams for real-time updates
- Progress badge shows `completed_count / total_count`

### D9: Tags — Simple User-Scoped Labels

Tags are user-defined labels with optional color:
- `tags` table: `name`, `color`, `user_id` (scoped per user)
- `item_tags` join table: `todo_item_id`, `tag_id`
- Tags can be reused across items within a user's account
- UI shows colored pills with an "x" to remove
- Adding a tag: type name → autocomplete from existing tags or create new

### D10: Active Storage for Attachments

Item attachments use Active Storage (`has_many_attached :files` on TodoItem):
- File cards show file type icon + filename
- Upload via standard file input in the attachments section
- No file type restrictions initially (reasonable size limit ~10MB via controller validation)
- Variants for image thumbnails

### D11: Archive as Boolean Flag

Archive sets `archived: true` on items/sections. Default scopes filter archived records:
- `scope :active, -> { where(archived: false) }`
- No restore UI in this feature — archived items are hidden but not deleted
- Context menu "Archive" action sends PATCH to update the archived flag

### D12: Security — Nested Resource Authorization

All item and section operations are scoped through `Current.user.todo_lists`:
```
@todo_list = Current.user.todo_lists.find(params[:todo_list_id])
@todo_item = @todo_list.todo_items.find(params[:id])
```
This ensures:
- Items/sections are only accessible through their parent list
- The parent list must belong to the current user
- Unauthorized access returns 404 (ActiveRecord::RecordNotFound)
- Strong params exclude `todo_list_id`, `user_id`, and ownership fields

### D13: Turbo Streams for Real-Time Updates

Key interactions that use Turbo Streams:
- **Item creation**: POST returns `turbo_stream.prepend` with new item + new input row
- **Item completion toggle**: PATCH returns `turbo_stream.replace` with updated item partial
- **Item deletion**: DELETE returns `turbo_stream.remove` for the item element
- **Section creation**: POST returns `turbo_stream.append` with new section
- **Reorder**: PATCH returns `turbo_stream.replace` for the reordered container
- **Archive**: PATCH returns `turbo_stream.remove` for the archived element

### D14: Animations and Micro-Interactions

Per the user's request for "fun little animations, movements, niceties":
- **Item creation**: New items fade in with a subtle slide-down animation
- **Item completion**: Checkbox fills with a teal pulse, opacity transitions smoothly
- **Drag lift**: Item elevates with shadow + rotation, move cursor changes to grab
- **Drop**: Item settles into place with a spring-like ease
- **Context menu**: Dropdown appears with CSS transition
- **Section collapse**: Items slide up/down with height transition
- **Delete**: Item fades out before removal
- **Inline input focus**: Purple glow shadow appears around the active input
- **Due date badges**: Subtle pulse animation on overdue items

### D15: Due Date Color Coding

Due date badges use color coding relative to the current date:

| Condition | Background | Text | Label |
|-----------|-----------|------|-------|
| Overdue (past) | #FEE2E2 | #991B1B | "Overdue" or date |
| Upcoming (0-3 days) | #FEF3C7 | #92400E | Date (e.g., "Mar 8") |
| Future (4-14 days) | #DBEAFE | #1E40AF | Date |
| Far future (>14 days) | #D1FAE5 | #065F46 | Date |

Calculated in a model helper method `TodoItem#due_date_style` returning the CSS class name.

### D16: Visual Reference Screens

| Screen | Node ID | Purpose |
|--------|---------|---------|
| New List Created - Detail View | `Bifu2` | Empty list after creation |
| Adding First Item - Inline | `Md812` | Inline item input with hints |
| Adding Section - Inline | `kxC0I` | Section input with icon picker |
| List With Items & Sections | `QBfz6` | Full list with sections and empty states |
| TODO List Detail | `nGCDe` | Populated list with items, badges, completed items |
| Section Context Menu | `Df59j` | Section ellipsis menu |
| Item Context Menu | `9xhXA` | Item right-click/ellipsis menu |
| Drag to Reorder | `mg9id` | Drag interaction with visual feedback |
| TODO Item Detail | `sogSu` | Full item detail two-column page |

### D17: Stimulus Controller Architecture

| Controller | Purpose | Key Actions |
|-----------|---------|-------------|
| `inline_item_controller` | Inline item creation | `save` (Enter), `cancel` (Esc), `focus` |
| `inline_section_controller` | Inline section creation | `save` (Enter), `cancel` (Esc), `selectIcon` |
| `context_menu_controller` | Context menu action dispatch | `edit`, `move`, `copy`, `archive`, `delete`, `insertTodo` |
| `drag_reorder_controller` | Drag-and-drop reordering | `dragStart`, `dragOver`, `dragEnd`, `drop` |
| `section_collapse_controller` | Section expand/collapse | `toggle` |
| `item_checkbox_controller` | Toggle item completion | `toggle` |
| `quick_actions_controller` | Quick action bar below input | `setDueDate`, `setPriority`, `assign` |
| `notes_editor_controller` | Toggle notes edit mode | `edit`, `save`, `cancel` |
| `checklist_controller` | Checklist item management | `add`, `toggle`, `remove` |
| `tag_manager_controller` | Tag add/remove | `add`, `remove`, `search` |

### D18: Stimulus Controller Scope — Targets Must Be Descendants

Copilot code review revealed that `data-controller` was placed on a dropdown element while form targets (`archiveForm`, `deleteForm`) were in sibling `<div>` elements. Stimulus requires all targets to be descendants of the controller element. Fix: wrap both the dropdown and hidden forms in a single container `<div>` with `data-controller`.

### D19: Turbo Stream vs HTML on Detail Page

The item detail page uses `data: { turbo: false }` on all forms (status selector, notes editor, mark complete, delete) to force full HTML redirects. This is necessary because the controller's Turbo Stream responses replace list-row partials (`_todo_item`, `_todo_item_completed`) which only exist on the list view, not the detail page. Without this, forms silently fail to update the UI.

### D20: Turbo Frame Navigation — `_top` for Full Page Links

Links inside `turbo_frame_tag` are intercepted by Turbo, which tries to replace just the frame. Item title links in `_todo_item.html.erb` use `data: { turbo_frame: "_top" }` to trigger full-page navigation to the item detail page. Without this, clicking shows "Content missing."

### D21: Drag-and-Drop — Turbo Frames as Draggable Units

After removing duplicate DOM IDs (Copilot fix), the drag controller was rewritten to use `turbo-frame.todo-item-frame` as the draggable elements. Key decisions:
- `draggable="true"` is on the `turbo_frame_tag`, not the inner div
- `data-item-id` and `data-section-id` attributes on the frame for identification
- CSS `turbo-frame.todo-item-frame { display: block; }` to make frames participate in layout
- Drop targets include items (above/below), section containers (cross-section), and unsectioned area
- `persistOrder()` collects all items from all containers and sends full order to server
- Section headers do NOT support drag reordering (deferred)

### D22: Security — Server-Side Ownership Enforcement

`assigned_to_user_id` is permitted in strong params but forced to `Current.user.id` server-side, regardless of what the client sends. This prevents users from assigning items to arbitrary user IDs even though the single-user stub model only allows self-assignment.

### D23: Position Shift — Order of Operations

When creating items with `position: 0` (prepend), existing items must be shifted BEFORE the new item is saved, wrapped in a transaction. If shifted after save, the new item's position also gets incremented, placing it at position 1 instead of 0.

### D24: Inline Section Creation — fetch() not requestSubmit()

The inline section input is a plain `<div>` with `<input>` fields, not a `<form>`. Therefore `this.element.requestSubmit()` fails silently. The controller uses `fetch()` POST with FormData instead, matching the inline item creation pattern.

### D25: Item Detail Sub-Resource Controllers

Each item detail section has its own controller for clean separation:
- `ChecklistItemsController`: create, toggle, destroy — redirects back to item detail
- `CommentsController`: create, destroy — redirects back to item detail
- `AttachmentsController`: create (multi-file), destroy — redirects back to item detail
- `TagsController`: create (find-or-create tag, create item_tag), destroy — redirects back to item detail

All use `data: { turbo: false }` or standard form submission with HTML redirects to avoid Turbo Stream conflicts on the detail page.

### D26: Blank Slate Visibility Toggle

The show page always renders BOTH the blank slate and the content area, using `style="display: none"` to toggle visibility. This ensures `#unsectioned-items` always exists in the DOM for Turbo Stream prepend targets. The `show-actions` Stimulus controller hides the blank slate and shows the content area when users click "Add First Item."

## Complexity Tracking

> No constitution violations detected. All design decisions align with core principles.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    | —          | —                                   |
