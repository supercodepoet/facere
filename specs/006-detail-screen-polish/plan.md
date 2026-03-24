# Implementation Plan: Detail Screen Polish

**Branch**: `006-detail-screen-polish` | **Date**: 2026-03-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-detail-screen-polish/spec.md`

## Summary

Polish the TODO List Detail and TODO Item Detail screens to match the visual reference in `todo-list-item-screens.pen`. Fix item row badges/pills, context menus, notes Save button, assignee/notify pickers from collaborator pool, due date calendar picker, and file attachment upload/display. No new models or migrations — this is purely view/controller/CSS work on existing infrastructure.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, Stimulus), Web Awesome Pro (CDN), Font Awesome Pro (CDN), Lexxy (rich text), Active Storage (file uploads), ActionText
**Storage**: SQLite (all environments)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web (responsive — desktop + mobile)
**Project Type**: Web application (Rails monolith)
**Performance Goals**: UI interactions under 1 second, file uploads display within 3 seconds
**Constraints**: Design reference in .pen file is authoritative. No new gems. No new database tables.
**Scale/Scope**: View-layer polish only — 2 screens, ~15 partials to modify

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | **PASS** | All changes use ERB, Stimulus, Turbo — no new JS frameworks |
| II. Library-First | **PASS** | Using existing Web Awesome Pro components (wa-dropdown, wa-icon) |
| III. Joyful User Experience | **PASS** | Entire feature is about matching the polished .pen design |
| IV. Clean Architecture & DDD | **PASS** | View-only changes, no business logic modifications |
| V. Code Quality & Readability | **PASS** | Partials stay under 200 lines, Stimulus controllers focused |
| VI. Separation of Concerns | **PASS** | UI logic in views/Stimulus, business logic unchanged |
| VII. Simplicity & YAGNI | **PASS** | Only changes needed to match design — no extras |

**All gates pass. No violations to track.**

## Project Structure

### Documentation (this feature)

```text
specs/006-detail-screen-polish/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
app/
├── views/
│   ├── todo_lists/
│   │   ├── _todo_item.html.erb              # MODIFY: Verify due date badge, priority dot, assignee avatars match design
│   │   ├── _todo_item_completed.html.erb    # MODIFY: Same badge updates for completed items
│   │   ├── _section.html.erb               # MODIFY: Ensure context menu matches design
│   │   ├── _section_context_menu.html.erb   # MODIFY: Add missing menu items (New list from group, Insert a to-do)
│   │   └── _item_context_menu.html.erb      # MODIFY: Verify all options match design
│   └── todo_items/
│       ├── show.html.erb                    # MODIFY: Layout polish, sidebar cards
│       ├── _notes_section.html.erb          # MODIFY: Save button (not Done), button styling
│       ├── _assignees_card.html.erb         # MODIFY: Picker shows all list members
│       ├── _due_date_card.html.erb          # MODIFY: Calendar picker, clear date option
│       ├── _notify_card.html.erb            # MODIFY: Picker shows all list members
│       ├── _attachments_section.html.erb    # MODIFY: File card display with icon/size
│       ├── _status_sidebar.html.erb         # VERIFY: Matches design
│       └── _priority_card.html.erb          # VERIFY: Matches design
├── javascript/
│   └── controllers/
│       ├── notes_autosave_controller.js     # MODIFY: Save button behavior
│       └── date_picker_controller.js        # VERIFY: Calendar picker works
└── assets/
    └── stylesheets/
        └── todo_lists.css                   # MODIFY: Badge, pill, context menu styles

config/
└── routes.rb                                # UNCHANGED — all routes exist
```

**Structure Decision**: View-layer only. No new files expected — all modifications to existing partials and stylesheets. The context menus, assignee picker, and notes section already exist as partials; they need content and behavior fixes, not creation.

## Complexity Tracking

> No constitution violations. Table not needed.
