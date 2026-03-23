# Implementation Plan: TODO Item Detail Screen

**Branch**: `004-todo-item-detail` | **Date**: 2026-03-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-todo-item-detail/spec.md`

## Summary

Build a comprehensive TODO item detail screen with two-column layout supporting: status/priority management, always-editable rich text notes (Lexxy editor with auto-save), checklist items with progress tracking, file attachments via Active Storage, comments with likes and replies, due date with countdown, assignees, notify-on-complete, tags, mark complete, and delete. Uses Hotwire for all interactivity, follows Fizzy (37signals) architecture patterns, and matches the design mockup in `todo-list-item-screens.pen`.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive + Turbo Streams + Turbo Frames + Stimulus), Web Awesome Pro (CDN), Font Awesome Pro (CDN), Lexxy (~> 0.1.26.beta, new), ActionText (Rails built-in), Active Storage (Rails built-in)
**Storage**: SQLite (all environments)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web application (desktop + responsive mobile)
**Project Type**: Web application (Rails monolith)
**Performance Goals**: Detail page renders < 2 seconds, all interactions provide immediate visual feedback
**Constraints**: Vanilla Rails first, single-user stub model for assignees/notifications, Fizzy as architecture reference
**Scale/Scope**: Single-user app, ~10 screens total, this feature enhances 1 existing screen

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | All features use Rails built-ins (ActionText, Active Storage, Hotwire). Lexxy is the official Rails rich text editor successor. |
| II. Library-First | PASS | Lexxy replaces Trix (better maintained successor). No custom rich text editor. Active Storage for attachments. |
| III. Joyful UX | PASS | Design mockup in .pen file is the source of truth. All colors, spacing, and interactions match the design. |
| IV. Clean Architecture | PASS | Fizzy-style scoped concerns for nested controllers. Business logic in models. |
| V. Code Quality | PASS | Following Rails conventions. Methods < 50 lines, files < 200 lines. |
| VI. Separation of Concerns | PASS | Stimulus for DOM, Turbo for server communication, models for logic. |
| VII. Simplicity & YAGNI | PASS | Single-user stubs for multi-user features. No premature abstractions. Native date input over custom calendar. |

**Post-Phase 1 Re-check**: All gates still pass. Lexxy is the only new dependency, justified as official Trix successor used by the reference project (Fizzy).

## Project Structure

### Documentation (this feature)

```text
specs/004-todo-item-detail/
├── plan.md              # This file
├── research.md          # Phase 0 output — technology decisions
├── data-model.md        # Phase 1 output — entity changes and migrations
├── quickstart.md        # Phase 1 output — setup instructions
├── contracts/
│   └── routes.md        # Phase 1 output — route definitions
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── todo_items_controller.rb       # Modified: enhanced show, status/priority update
│   ├── comments_controller.rb         # Modified: add update action
│   ├── comment_likes_controller.rb    # New: like/unlike toggle
│   ├── notify_people_controller.rb    # New: add/remove notify people
│   ├── checklist_items_controller.rb  # Existing (minor updates)
│   ├── attachments_controller.rb      # Existing (minor updates)
│   └── tags_controller.rb            # Existing (minor updates)
├── models/
│   ├── todo_item.rb                   # Modified: expanded enums, new associations
│   ├── comment.rb                     # Modified: replies, likes, edited_at
│   ├── comment_like.rb                # New
│   ├── notify_person.rb               # New
│   └── concerns/
│       └── todo_item_scoped.rb        # New: Fizzy-style scoped concern
├── views/
│   └── todo_items/
│       ├── show.html.erb              # Modified: full detail layout
│       ├── _notes_section.html.erb    # Modified: Lexxy always-editable
│       ├── _checklist_section.html.erb # Existing (enhanced)
│       ├── _attachments_section.html.erb # Existing (enhanced)
│       ├── _comments_section.html.erb  # Modified: likes, replies, edit
│       ├── _comment.html.erb           # New: single comment partial
│       ├── _status_sidebar.html.erb    # Modified: 4 statuses
│       ├── _priority_card.html.erb     # New: priority selector card
│       ├── _assignees_card.html.erb    # New: assignees display
│       ├── _due_date_card.html.erb     # New: due date with countdown
│       ├── _notify_card.html.erb       # New: notify on complete
│       └── _actions_card.html.erb      # New: mark complete + delete
├── javascript/
│   └── controllers/
│       ├── notes_autosave_controller.js    # New: Lexxy auto-save
│       ├── comment_like_controller.js      # New: like toggle
│       ├── date_picker_controller.js       # New: due date quick picks
│       └── notes_editor_controller.js      # Remove (replaced by always-editable)
└── assets/
    └── stylesheets/
        └── todo_lists.css                  # Modified: new detail page styles

config/
└── routes.rb                               # Modified: new nested routes

db/migrate/
├── XXXXXX_rename_medium_to_normal_priority.rb
├── XXXXXX_add_on_hold_status_to_todo_items.rb  # (no-op, string column)
├── XXXXXX_add_reply_and_edit_support_to_comments.rb
├── XXXXXX_create_comment_likes.rb
└── XXXXXX_create_notify_people.rb

test/
├── controllers/
│   ├── comment_likes_controller_test.rb    # New
│   └── notify_people_controller_test.rb    # New
├── models/
│   ├── comment_like_test.rb                # New
│   └── notify_person_test.rb               # New
└── system/
    └── todo_item_detail_test.rb            # New: comprehensive system tests
```

**Structure Decision**: Standard Rails monolith structure, following existing patterns. New files follow the established naming conventions. No new directories needed beyond what Rails conventions provide.

**Icon Mapping Note**: The .pen design file uses Lucide icon names. Implementation MUST use Font Awesome Pro icons via `<wa-icon>` per constitution. A mapping from design names to Font Awesome names is required (e.g., `trash-2` → `trash`, `send` → `paper-plane`, `x` → `xmark`).

## Complexity Tracking

No constitution violations to justify. All decisions align with existing principles.

## Implementation Notes

- **Lexxy integration**: Pin via `pin "lexxy", to: "lexxy.min.js"` (NOT `bin/importmap pin lexxy`). Also pin `@rails/activestorage`. Remove trix/actiontext imports.
- **button_to vs link_to in flex layouts**: `button_to` creates `<form>` wrappers that break flex layouts. Use `link_to` with `data-turbo-method` for simple PATCH/DELETE actions in flex containers (checklist items, status buttons).
- **Priority enum**: Internal value is `"medium"` (not "normal"), display label is "Medium".
- **Status badge**: Always purple `#8B5CF6` in the header, regardless of actual status.
- **Notes toggle**: Uses Edit/Done button toggle despite original spec saying always-editable. Design reference takes precedence.
