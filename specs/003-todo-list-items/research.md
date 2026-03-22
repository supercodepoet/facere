# Research: TODO List Items Management

**Feature**: 003-todo-list-items | **Date**: 2026-03-21

## R1: Rich Text Editor — Fizzy vs Lexxy vs ActionText

**Decision**: Use ActionText with Trix (Rails built-in)

**Rationale**: The user referenced "Fizzy" as a rich text editor, but research revealed that Fizzy (`basecamp/fizzy`) is 37signals' Kanban project management tool — NOT an editor. The actual rich text editor successor to Trix is **Lexxy** (`basecamp/lexxy`), currently in beta (v0.9.0.beta). Given:
- Lexxy is still beta and may have breaking changes
- The user also said "use standard Rails tools like ActionText"
- ActionText with Trix is built into Rails 8.1 and provides paragraphs, bullet lists, bold, italic, links, file embeds
- Lexxy is designed as a drop-in replacement for Trix within ActionText — easy future migration

ActionText with Trix is the safest, most Rails-conventional choice. When Lexxy reaches stable, the migration path is: `gem "lexxy"` + `bin/rails lexxy:install`.

**Alternatives considered**:
- Lexxy (beta, risk of instability in production)
- Plain textarea + markdown parser (no WYSIWYG editing, poor UX)
- Third-party editors (SimpleMDE, EasyMDE) — violates Library-First principle when Rails has ActionText built in

## R2: Web Awesome Components for Context Menus

**Decision**: Use `wa-dropdown` + `wa-dropdown-item`

**Rationale**: Web Awesome Pro does NOT have `wa-menu` or `wa-menu-item` components (404 on docs). The `wa-dropdown` component with `wa-dropdown-item` children serves as the menu system. Key features:
- `variant="danger"` for destructive actions (Delete)
- `wa-select` event for action dispatch (bubbles, works with Stimulus)
- Built-in transitions and focus management
- Trigger slot for button that opens the dropdown

**Alternatives considered**:
- Custom HTML/CSS menu (violates Library-First; WA component exists)
- `wa-popup` (low-level positioning utility, no accessibility built-in)
- `wa-popover` (designed for interactive content but not menu patterns)

## R3: Drag-and-Drop Implementation

**Decision**: Native HTML5 Drag and Drop API with Stimulus controller

**Rationale**: The HTML5 DnD API is sufficient for this use case:
- Supported in all modern browsers
- Works with Turbo (no framework conflicts)
- Stimulus controller manages event listeners and visual feedback
- Server persists position changes via PATCH request

No external DnD library (Sortable.js, @hello-pangea/dnd) needed — those are React/SPA oriented and violate Vanilla Rails First principle.

**Key implementation notes**:
- Use `draggable="true"` on item/section rows
- Grip handle (`.drag-handle`) as the visual indicator
- `dragstart` event adds lift animation (rotation, shadow)
- `dragover` event shows drop indicator line
- `drop` event sends PATCH to server with `{ id, new_position, new_section_id }`
- Server recalculates all positions in a transaction

**Alternatives considered**:
- Sortable.js (external dependency, overkill for this use case)
- Server-only reordering with up/down buttons (poor UX, doesn't match design)

## R4: Inline Item Creation Flow

**Decision**: Turbo Streams with Stimulus controller for keyboard handling

**Rationale**: The design shows an Enter-to-save-and-continue flow:
1. User clicks "Add Item" → Turbo Frame renders inline input row
2. User types name, presses Enter → Stimulus controller intercepts keydown
3. Controller sends POST via `fetch()` with `Accept: text/vnd.turbo-stream.html`
4. Server responds with Turbo Streams: `prepend` new item + `replace` input (reset for next)
5. User can immediately type next item — no page reload, no focus loss

This pattern keeps the server authoritative (validation, persistence) while Stimulus handles keyboard interaction and focus management.

**Alternatives considered**:
- Full Turbo Form submission (loses cursor focus, slower feel)
- Optimistic client-side creation (inconsistent with server-rendered pattern)

## R5: Attachments via Active Storage

**Decision**: Use Active Storage (`has_many_attached :files`)

**Rationale**: Active Storage is built into Rails 8.1 and handles:
- File upload with direct upload support
- Image variants for thumbnails
- Cloud storage compatibility (local disk for development)
- Integration with ActionText for inline embeds

**Alternatives considered**:
- Shrine gem (external dependency, more flexible but unnecessary complexity)
- CarrierWave (older pattern, Active Storage is the Rails standard)

## R6: Checklist Implementation

**Decision**: Separate `ChecklistItem` model with Turbo Streams

**Rationale**: Checklist items are a simple list of sub-tasks within a TODO item. A dedicated model provides:
- Individual completion tracking
- Position-based ordering
- Independent CRUD via nested route
- Progress calculation (`completed_count / total_count`)

Turbo Streams provide real-time updates when checking/unchecking items without page reload.

**Alternatives considered**:
- JSON array stored on TodoItem (no individual tracking, harder to query)
- ActionText checklist (Trix has limited checkbox support)

## R7: Tags — User-Scoped with Join Table

**Decision**: Separate `Tag` model with `ItemTag` join table

**Rationale**: Tags need to be:
- Reusable across items within a user's account
- Searchable for autocomplete when adding
- Independently manageable (create, rename, delete)
- Color-coded per the design

A join table allows many-to-many relationship without duplicating tag data.

**Alternatives considered**:
- Array of strings on TodoItem (no reusability, no color, harder to manage)
- `acts_as_taggable` gem (external dependency for simple use case)

## R8: Priority as String Field

**Decision**: Store priority as a string column with enum-like constants

**Rationale**: Four priority levels (none, low, medium, high) as string values:
- Simple to store and query
- No migration needed if levels change
- Constants on model for validation and view rendering
- Maps directly to visual indicators (no dot, green dot, orange dot, red dot)

**Alternatives considered**:
- Integer enum (less readable in database, migration needed to add levels)
- Separate Priority model (over-engineering for 4 static values)

## R9: Status Field

**Decision**: String field with three values: "todo", "in_progress", "done"

**Rationale**: Status tracks item lifecycle and is displayed as badges in both list and detail views. String storage with model constants:
- `STATUSES = %w[todo in_progress done].freeze`
- Default: "todo"
- Completing an item (checkbox) also sets status to "done"
- Validation: inclusion in STATUSES

**Alternatives considered**:
- State machine gem (over-engineering; transitions are simple and non-constrained)
- Boolean fields per state (limited, doesn't scale)
