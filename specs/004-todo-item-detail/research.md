# Research: TODO Item Detail Screen

**Branch**: `004-todo-item-detail` | **Date**: 2026-03-22

## Decision 1: Rich Text Editor — Lexxy

**Decision**: Use Lexxy (basecamp/lexxy) as the rich text editor for the Notes section, replacing Trix.

**Rationale**: Lexxy is the official successor to Trix, built on Meta's Lexical framework. It provides a drop-in replacement for ActionText with superior features (markdown support, code highlighting, tables, better semantic HTML with proper `<p>` tags). Fizzy (the 37signals reference project) already uses Lexxy in production for card descriptions and comment bodies.

**Alternatives considered**:
- **Trix (current)**: Already integrated via ActionText, but no longer actively developed. Lexxy supersedes it.
- **Prosemirror / TipTap**: More mature, but not Rails-native. Would require custom ActionText integration.

**Integration approach**:
- Gem: `gem 'lexxy', '~> 0.1.26.beta'`
- JavaScript: Pin via Importmap (`pin "lexxy", to: "lexxy.js"`) + `import "lexxy"` in application.js
- CSS: Import Lexxy stylesheets (lexxy.css, lexxy-editor.css, lexxy-content.css, lexxy-variables.css)
- Configuration: Set `config.lexxy.override_action_text_defaults = true` for seamless ActionText replacement
- Auto-save: Listen for `lexxy:change` event, debounce with Stimulus controller, submit form via fetch

## Decision 2: Notes Auto-Save Pattern (Fizzy Reference)

**Decision**: Implement auto-save using a Stimulus controller following Fizzy's `auto_save_controller.js` pattern — debounced saves on content change with immediate save on blur/disconnect.

**Rationale**: Fizzy's auto-save pattern is battle-tested: 3-second debounce on `change` events, immediate save on `disconnect()` to prevent data loss during navigation. This aligns with the always-editable Notes requirement.

**Alternatives considered**:
- **Server-sent save via Turbo Stream**: Adds complexity without benefit for single-field saves.
- **Local storage draft recovery**: Fizzy uses `local_save_controller.js` for this, but overkill for notes that auto-save to server.

**Implementation approach**:
- Stimulus controller: `notes_autosave_controller.js`
- Listens for `lexxy:change` event on the editor
- Debounces 2 seconds (shorter than Fizzy's 3s since notes are the primary content area)
- Submits the enclosing form via `fetch()` with FormData
- On `disconnect()`: immediate save if dirty
- No save button in the UI — fully automatic

## Decision 3: Comment Likes and Replies — Data Model

**Decision**: Add `CommentLike` model and self-referential `parent_id` on `Comment` for replies. Follow Fizzy's reaction pattern for likes.

**Rationale**: Fizzy implements reactions as a separate model (`Reaction`) with polymorphic association. For our simpler case (single reaction type: like), a dedicated `CommentLike` model with unique constraint on `[comment_id, user_id]` is cleaner. Replies use self-referential `parent_id` on Comment, limited to one nesting level in the view layer.

**Alternatives considered**:
- **Counter cache for likes**: Would prevent toggle detection. A join table is needed to know if the current user has liked.
- **Polymorphic reactions (Fizzy-style)**: Over-engineered for a single "like" reaction type.
- **Threaded comments (unlimited nesting)**: Adds UI/data complexity. One level of nesting is sufficient per spec.

## Decision 4: Status and Priority Expansion

**Decision**: Expand the existing `status` enum to include "on_hold" and expand `priority` to include "urgent". Update the `sync_completion_and_status` callback to handle the full sync behavior.

**Rationale**: The existing model already has `status` (todo/in_progress/done) and `priority` (none/low/medium/high). We need to add "on_hold" to status and "urgent" to priority. The existing `sync_completion_and_status` before_save hook already handles status↔completed synchronization — it just needs updating for the new "on_hold" status and the "normal" rename.

**Alternatives considered**:
- **Separate state machine gem**: Unnecessary. The status transitions are simple enough for a before_save callback.
- **Keep 3 statuses**: Spec requires 4 (To Do, In Progress, On Hold, Done).

**Implementation notes**:
- Rename "medium" priority to "normal" in the enum (migration + model update)
- Add "urgent" priority level
- Add "on_hold" status level
- Update `sync_completion_and_status` to handle: setting "Done" → completed=true; setting anything else → completed=false; setting completed=true → status="done"; unmarking complete → status="todo"

## Decision 5: Notify on Complete — Single-User Stub

**Decision**: Implement `NotifyPerson` model as a simple association table (todo_item_id, user_id, role). No actual notification delivery. Single-user stub: user adds themselves.

**Rationale**: Per spec and feature 003 learnings, this is a single-user stub. The data model supports future multi-user expansion but no email/push notification delivery is built now. Follow the same pattern as assignees.

## Decision 6: Comment Edit/Delete UX Pattern

**Decision**: Use inline editing for comment edits (Turbo Frame per comment) and cascade-delete for parent comment deletion. Follow Fizzy's pattern of wrapping each comment in a Turbo Frame.

**Rationale**: Fizzy wraps each comment in `turbo_frame_tag comment` enabling isolated inline editing. Edit replaces the comment body with an editor; save replaces the frame. Delete uses `dependent: :destroy` on replies association.

## Decision 7: Controller Architecture — Fizzy-Style Scoped Concerns

**Decision**: Use scoped concerns (e.g., `TodoItemScoped`) for nested controllers, following Fizzy's `CardScoped` pattern.

**Rationale**: Fizzy uses `CardScoped` concern that sets `@card` via `Current.user.accessible_cards.find_by!()`. This pattern keeps nested controllers DRY and ensures authorization. Our existing controllers already partially follow this — formalize it into concerns.

**Implementation approach**:
- `TodoItemScoped` concern: sets `@todo_list` and `@todo_item` from params, scoped through `Current.user`
- Include in: `ChecklistItemsController`, `CommentsController`, `AttachmentsController`, `TagsController`, and new `CommentLikesController`

## Decision 8: New Controllers Needed

**Decision**: Add `CommentLikesController` and `NotifyPeopleController`. Expand `CommentsController` with `update` action. No new controllers needed for status/priority (existing `TodoItemsController#update` handles these).

**Rationale**: Likes and notify-people are separate resources following REST conventions. Comment editing adds an `update` action to the existing controller. Status/priority changes go through the existing item update endpoint.

## Decision 9: Attachment Upload — Active Storage Direct Upload

**Decision**: Use Active Storage direct uploads for a better UX, showing upload progress without blocking the page.

**Rationale**: The existing implementation uses standard multipart form uploads. Direct uploads provide a smoother experience — files upload in the background and appear as cards when complete. Rails 8.1 includes built-in direct upload JavaScript.

## Decision 10: Date Picker — Native Input

**Decision**: Use native HTML date input with `showPicker()` for the due date, enhanced with quick-pick buttons (Today, Tomorrow, Next Week, No Date) matching the design.

**Rationale**: The design shows a custom date picker popover with quick-pick options. Building a full custom calendar is out of scope per YAGNI. The native date input provides reliable cross-browser date selection. Quick-pick buttons can be implemented as simple Stimulus-controlled buttons that set the date input value.

**Alternatives considered**:
- **Custom calendar component**: Matches design exactly but significant effort for a date picker. Defer to a future enhancement.
- **Third-party date picker library**: Adds a JS dependency that conflicts with Vanilla Rails First principle.
