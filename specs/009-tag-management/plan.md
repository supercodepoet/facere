# Implementation Plan: Tag Management

**Branch**: `009-tag-management` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-tag-management/spec.md`

## Summary

Upgrade the TODO item detail view's tag management from a simple inline add/remove form to a rich tag editor dropdown with search, toggle, create/edit/delete workflows, and custom color picker. Builds entirely on the existing Tag model and TagsController — no schema changes, no new dependencies. Uses Hotwire (Turbo Frames + Stimulus) for all interactions.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, Stimulus), Font Awesome Pro (CDN kit)
**Storage**: SQLite (existing Tag and ItemTag tables — no migrations needed)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web (desktop + mobile responsive)
**Project Type**: Web application (Rails monolith)
**Performance Goals**: Tag search filtering < 16ms (client-side), all server responses < 200ms
**Constraints**: No new gems, no JavaScript frameworks, Hotwire-only interactivity
**Scale/Scope**: Typical user has < 100 tags; editor handles up to ~500 tags smoothly

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Uses Turbo Frames, Turbo Streams, Stimulus — no external JS frameworks |
| II. Library-First | PASS | No custom code where Rails/Hotwire handles it; native `<input type="color">` for custom colors |
| III. Joyful UX | PASS | Rich dropdown editor with search, color swatches, smooth transitions per .pen designs |
| IV. Clean Architecture & DDD | PASS | Tag CRUD stays in TagsController, business logic in models, Stimulus for DOM only |
| V. Code Quality | PASS | Small methods, early returns, no deep nesting anticipated |
| VI. Separation of Concerns | PASS | Server handles data/auth, Stimulus handles DOM filtering, Turbo handles partial updates |
| VII. Simplicity & YAGNI | PASS | No new models, no migrations, extends existing controller — minimal footprint |

**Post-Phase 1 Re-check**: All gates still pass. No schema changes, no new dependencies, no architectural additions.

## Project Structure

### Documentation (this feature)

```text
specs/009-tag-management/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research decisions
├── data-model.md        # Data model documentation
├── quickstart.md        # Developer quickstart
├── contracts/           # Endpoint contracts
│   └── tag-endpoints.md
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (files to create/modify)

```text
app/
├── controllers/
│   └── tags_controller.rb              # MODIFY — add index, update; enhance create/destroy
├── models/
│   ├── tag.rb                          # EXISTING — no changes needed
│   └── item_tag.rb                     # EXISTING — no changes needed
├── views/
│   └── todo_items/
│       ├── show.html.erb               # MODIFY — update tags turbo-frame section
│       ├── _tags_card.html.erb         # REPLACE — new design with editor trigger
│       ├── _tag_editor.html.erb        # CREATE — dropdown with search + tag list
│       ├── _tag_form.html.erb          # CREATE — create/edit form with color picker
│       └── _tag_delete_confirm.html.erb # CREATE — delete confirmation modal
├── javascript/
│   └── controllers/
│       └── tag_editor_controller.js    # CREATE — search filter + view state management
└── assets/
    └── stylesheets/
        └── tag_editor.css              # CREATE — tag editor dropdown + color picker styles

config/
└── routes.rb                           # MODIFY — expand tag resources

test/
├── controllers/
│   └── tags_controller_test.rb         # MODIFY — add tests for index, update, permanent delete
└── system/
    └── tag_management_test.rb          # CREATE — system tests for full tag editor flows
```

**Structure Decision**: Standard Rails monolith structure. All changes fit within existing directories. One new Stimulus controller, three new view partials, one new CSS file.

## Implementation Phases

### Phase 1: Routes & Controller Foundation

Expand routes and TagsController to support the full tag lifecycle.

**Routes changes**:
- Expand `resources :tags, only: [:create, :destroy]` to `only: [:index, :create, :update, :destroy]`

**Controller changes**:
- `index`: Load `Current.user.tags` and `@todo_item.tags`, render tag editor partial
- `update`: Find tag by `Current.user.tags.find(params[:id])`, update name/color, respond with Turbo Stream
- Enhance `create`: Respond with Turbo Stream (replace tag editor + tags card)
- Enhance `destroy`: Accept `permanent` param — if true, delete `Current.user.tags.find(params[:id])` entirely; otherwise, remove item_tag association only. Both respond with Turbo Stream

### Phase 2: Tag Editor Dropdown View

Replace `_tags_card.html.erb` with a new design featuring the editor trigger.

**_tags_card.html.erb** (replace):
- Display applied tags as colored pills (matching current design)
- Add a clickable trigger (tag icon + "Add tag" or similar) that opens the tag editor via Turbo Frame

**_tag_editor.html.erb** (new):
- Search input field at top
- Scrollable tag list: each row shows color dot, name, checkmark if applied
- Each row is clickable to toggle the tag on/off (POST/DELETE via Turbo)
- Each row shows ellipsis icon on hover → opens per-row dropdown (Edit Tag / Delete Tag)
- "Create new tag..." action at bottom
- Wrapped in a Turbo Frame for inline loading

### Phase 3: Create & Edit Tag Forms

**_tag_form.html.erb** (new, shared for create/edit):
- Text field for tag name
- Color picker: preset swatches (~10 circles) + native `<input type="color">` for custom
- Action buttons: Cancel / Create Tag (or Save Changes for edit)
- Pre-fills name and color when editing
- Form submits via Turbo to create or update action

**Color picker behavior**:
- Preset swatches: clickable circles that set a hidden `tag[color]` field
- Custom color: native color input that also sets the hidden field
- Visual indicator showing which color is currently selected

### Phase 4: Delete Confirmation & Tag Editor Stimulus Controller

**_tag_delete_confirm.html.erb** (new):
- Modal overlay using existing `modal_controller.js` pattern
- Shows tag name with color dot
- Warning text: "Are you sure you want to delete this tag? It will be removed from all items."
- Cancel / Delete Tag buttons
- Delete button submits permanent delete via Turbo

**tag_editor_controller.js** (new):
- `search` action: filters tag list rows by matching input text against tag names (client-side, case-insensitive)
- `showCreate` / `showEdit` / `showList` actions: toggle visibility between tag list view and create/edit form views
- `selectColor` action: handles preset swatch clicks, updates hidden field and visual selection state
- Connect/disconnect: manages dropdown open/close lifecycle

### Phase 5: Styles & Visual Polish

**tag_editor.css** (new):
- Tag editor dropdown: positioned below trigger, shadow, rounded corners, max-height with scroll
- Search field styling
- Tag row: hover state reveals ellipsis, checkmark styling, color dot
- Color picker: preset swatch circles, selected state ring, custom color input styling
- Delete confirmation modal: consistent with existing modal pattern
- Responsive: ensure dropdown works on mobile (full-width on small screens)

### Phase 6: Tests

**Controller tests** (tags_controller_test.rb — expand):
- Test index returns tag list with correct checkmarks
- Test create with Turbo Stream response
- Test update name, update color, validation errors (duplicate name)
- Test destroy (remove from item vs permanent delete)
- Test auth: unauthenticated redirects, other user's tags return 404

**System tests** (tag_management_test.rb — new):
- Open tag editor, toggle tag on/off
- Search and filter tags
- Create new tag with preset color
- Create new tag with custom color
- Edit existing tag name and color
- Delete tag from ellipsis menu with confirmation
- Delete tag from edit form
- Cancel flows (create cancel, edit cancel, delete cancel)

## Complexity Tracking

> No constitution violations — table not needed.

## Key Design Decisions

1. **Client-side search over server-side**: Tags are per-user and small sets (<100 typical). Filtering in Stimulus avoids round-trips and feels instant.

2. **Single Stimulus controller for editor state**: Rather than multiple controllers, one `tag_editor_controller.js` manages all view transitions (list ↔ create ↔ edit), search, color picker, ellipsis menus, and delete modal. Keeps related logic together and enables coordination (e.g., only one ellipsis menu open at a time).

3. **Turbo Streams for data mutations, Stimulus for UI state**: Creating/editing/deleting tags hits the server via Turbo (data integrity + validation). Showing/hiding the create form or filtering the search list is pure Stimulus (no server needed for UI transitions).

4. **Ellipsis menus managed by parent controller, not per-row dropdown controllers**: Original plan was to reuse `dropdown_controller.js` per tag row. During implementation, discovered that per-row controllers can't coordinate — multiple menus could open simultaneously. Moved all ellipsis management into `tag_editor_controller.js` with `toggleEllipsis`/`closeAllEllipsis` methods and `position: fixed` + `getBoundingClientRect()` positioning to escape scroll overflow clipping.

5. **No schema changes**: The existing Tag and ItemTag models fully support all requirements. Adding `update` and enhanced `destroy` to the controller is all that's needed.

6. **Shared form partial for create/edit**: `_tag_form.html.erb` handles both create and edit modes, reducing duplication. Mode is determined by `mode` parameter (`:create` or `:edit`), not `tag.persisted?`, because the edit view uses a placeholder `Tag.new(id: 0)` whose fields are populated by Stimulus JS.

7. **Sibling turbo-frames, not nested**: Critical architecture decision discovered during implementation. The tags card (`item_tags_`) and the editor (`tag_editor_`) MUST be sibling frames under a shared wrapper `div` with `data-controller="tag-editor"`. Nesting the editor inside the tags card caused the Stimulus controller and its targets to be destroyed on every Turbo Stream replacement, breaking subsequent toggles.

8. **Turbo Stream replacements must preserve Stimulus data attributes**: All turbo stream templates (`create.turbo_stream.erb`, `destroy.turbo_stream.erb`, `update.turbo_stream.erb`) must include `data-tag-editor-target="editorFrame"` and `data-src` on the replacement `<turbo-frame>` element. Without these, the Stimulus controller loses its target references.

9. **Always-active outside-click listener**: The document click listener for closing the popover is registered in `connect()` (not `openEditor`). Turbo Stream replacements can disconnect/reconnect the controller; registering only on open would lose the listener.

## Implementation Learnings

Discovered during the build phase — these are patterns and gotchas not apparent from the spec/plan alone:

- **Popover positioning**: The tag editor uses `position: absolute; bottom: 0; margin-bottom: 30px` to anchor just above the "Manage tags" trigger. `bottom: 100%` placed it too far from the trigger.
- **Preset color count matters**: 8 color swatches wrapped to a second line on the 280px-wide popover. Reduced to 7 (removed pink `#F472B6`) to keep a single row.
- **Live preview in forms**: The tag name input has `data-action="input->tag-editor#updatePreview"` to update the preview pill text as the user types. The color picker also updates the preview pill's background and text color.
- **Tag pill gap**: `.tag-pill` needs explicit `gap: 6px` for spacing between the color dot and tag name text. Without it, the dot and text run together.
- **Integration test 404 pattern (confirmed)**: `assert_raises(ActiveRecord::RecordNotFound)` does NOT work in `ActionDispatch::IntegrationTest` — Rails rescues the exception and returns 404. Use `assert_response :not_found` instead. (Already in constitution, re-confirmed here.)

## Future Improvements

Identified during implementation but deferred:

- **System tests**: Full Capybara system tests for the tag editor UI flows (open/toggle/search/create/edit/delete) were scoped but not implemented. Should be added before shipping to production.
- **Keyboard navigation**: The tag editor has no keyboard support — arrow keys to navigate tag list, Enter to toggle, Escape to close. Important for accessibility (WCAG 2.1 AA).
- **Tag ordering options**: Currently alphabetical. Users may want ordering by frequency of use, most recently created, or custom drag-to-reorder.
- **Bulk tag operations**: Apply/remove a tag to multiple items at once from the list view.
- **Tag count display**: Show how many items each tag is applied to in the editor dropdown.
- **Color picker refinement**: The native `<input type="color">` works but looks different across browsers. A custom color picker component would give more consistent UX.
- **Empty state polish**: When no tags exist, the editor shows "No tags yet" text. Could be more inviting with an illustration or onboarding prompt.
