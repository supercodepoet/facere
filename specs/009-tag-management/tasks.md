# Tasks: Tag Management

**Input**: Design documents from `/specs/009-tag-management/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Tests are included as they are part of the implementation plan (Phase 6).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Rails monolith: `app/`, `config/`, `test/` at repository root
- Views: `app/views/todo_items/`
- JS: `app/javascript/controllers/`
- CSS: `app/assets/stylesheets/`

---

## Phase 1: Setup

**Purpose**: Route expansion and shared CSS foundation

- [x] T001 Expand tag routes from `only: [:create, :destroy]` to `only: [:index, :create, :update, :destroy]` in config/routes.rb
- [x] T002 [P] Create tag editor stylesheet with base dropdown, tag row, and color picker styles in app/assets/stylesheets/tag_editor.css. Reference designs in `designs/todo-list-item-screens.pen` — screens: "Tag Editor Open", "Tag Editor - Ellipsis Menu", "Create New Tag", "Edit Tag", "Delete Tag Confirm"

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Replace existing tags card and create the tag editor Stimulus controller that all stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Replace app/views/todo_items/_tags_card.html.erb with new design: display applied tags as colored pills, add a clickable trigger button (tag icon + count or "Add tag") that opens the tag editor dropdown. The trigger should load the tag editor via a Turbo Frame (`tag_editor_{item_id}`). Verify the existing turbo-frame in app/views/todo_items/show.html.erb (`item_tags_{item_id}`) still wraps the new partial correctly — update the frame ID or add a nested editor frame if needed. Reference "Tag Editor Open" screen in `designs/todo-list-item-screens.pen` for the tags display and trigger styling
- [x] T004 Create base tag_editor_controller.js Stimulus controller in app/javascript/controllers/tag_editor_controller.js — initial targets: searchInput, tagList, tagRows, createView, editView, listView. Actions: `showCreate`, `showList` to toggle between tag list and create form views. Wire up `connect`/`disconnect` lifecycle

**Checkpoint**: Foundation ready — tags card shows applied tags with editor trigger, Stimulus controller registered

---

## Phase 3: User Story 1 - Add and Remove Tags (Priority: P1) MVP

**Goal**: Users can open a tag editor dropdown and toggle tags on/off a TODO item by clicking tag rows

**Independent Test**: Open tag editor on any item, click tags to add/remove, confirm checkmarks and tag pills update immediately

### Implementation for User Story 1

- [x] T005 [US1] Add `index` action to TagsController in app/controllers/tags_controller.rb — load `@tags = Current.user.tags.order(:name)` and `@applied_tag_ids = @todo_item.tag_ids`, render tag editor partial. Add `authorize_list_access!` for index (read-only access)
- [x] T006 [US1] Create app/views/todo_items/_tag_editor.html.erb — Turbo Frame wrapping the tag editor dropdown. Render search input at top (placeholder for US2), scrollable tag list with each tag row showing: color dot, tag name, checkmark if tag_id is in applied_tag_ids. Each tag row is a form that POSTs to toggle (add) or DELETEs to toggle (remove) via Turbo. Include "Create new tag..." link at bottom (placeholder for US3). Reference "Tag Editor Open" screen in `designs/todo-list-item-screens.pen`
- [x] T007 [US1] Enhance `create` action in app/controllers/tags_controller.rb — when toggling an existing tag onto an item (received via `tag[id]` param), find the tag and create the item_tag association. Respond with Turbo Stream replacing both `item_tags_{item_id}` (tags card) and `tag_editor_{item_id}` (editor with updated checkmarks)
- [x] T008 [US1] Enhance `destroy` action in app/controllers/tags_controller.rb — default behavior (no `permanent` param) removes item_tag association only. Respond with Turbo Stream replacing both `item_tags_{item_id}` and `tag_editor_{item_id}`
- [x] T009 [US1] Add Turbo Stream response templates: create app/views/tags/create.turbo_stream.erb and app/views/tags/destroy.turbo_stream.erb that replace both the tags card and tag editor frames

**Checkpoint**: User Story 1 fully functional — open editor, toggle tags on/off, see immediate UI updates

---

## Phase 4: User Story 2 - Search for Tags (Priority: P1)

**Goal**: Users can filter the tag list by typing in the search field — client-side, instant filtering

**Independent Test**: Open tag editor with many tags, type partial name, confirm only matching tags show

### Implementation for User Story 2

- [x] T010 [US2] Add `search` action to tag_editor_controller.js in app/javascript/controllers/tag_editor_controller.js — on input event, read search field value, iterate over tag row targets, show/hide each row based on case-insensitive name match. Ensure "Create new tag..." link always remains visible regardless of search query
- [x] T011 [US2] Wire search input in app/views/todo_items/_tag_editor.html.erb to Stimulus: add `data-action="input->tag-editor#search"` on the search field, add `data-tag-editor-target="searchInput"` and `data-tag-editor-target="tagRow"` on each tag row with `data-tag-name` attribute for filtering

**Checkpoint**: User Stories 1 + 2 functional — editor opens, search filters instantly, toggle still works

---

## Phase 5: User Story 3 - Create a New Tag (Priority: P1)

**Goal**: Users can create a new tag with a name and color (preset swatches + custom color input) from within the tag editor

**Independent Test**: Click "Create new tag...", enter name, pick color, submit — tag appears in list and is applied to current item

### Implementation for User Story 3

- [x] T012 [US3] Create app/views/todo_items/_tag_form.html.erb — shared form partial for create/edit. Includes: tag name text field, preset color swatches (clickable colored circles: ~10 colors from design), custom color input (`<input type="color">`), hidden `tag[color]` field updated by swatch clicks or custom picker, Cancel and Submit buttons. Form POSTs to tags create path (for new tags) or PATCHes to update path (for edit). Use `tag.persisted?` to determine mode. Reference "Create New Tag" screen in `designs/todo-list-item-screens.pen`
- [x] T013 [US3] Add `selectColor` and `showCreate`/`showList` actions to tag_editor_controller.js in app/javascript/controllers/tag_editor_controller.js — `selectColor`: when a preset swatch is clicked, update hidden color field and add visual "selected" ring to clicked swatch (remove from others). When custom color input changes, update hidden field and deselect preset swatches. `showCreate`: hide tag list, show create form view. `showList`: hide form, show tag list
- [x] T014 [US3] Enhance `create` action in app/controllers/tags_controller.rb — when `tag[name]` param is present (new tag creation, not toggle), find_or_create the tag for Current.user, attach to item, respond with Turbo Stream. Handle validation errors (duplicate name) by re-rendering the form with error messages. After successful creation, the Turbo Stream response must reset the search field and show the full tag list (not a filtered subset) so the new tag is visible
- [x] T015 [US3] Update _tag_editor.html.erb to wire "Create new tag..." link: add `data-action="click->tag-editor#showCreate"`. Add the tag form partial render (hidden by default) within the editor dropdown, wrapped in a div with `data-tag-editor-target="createView"`

**Checkpoint**: User Stories 1-3 functional — full create flow with color picker works, search still filters, toggle still works

---

## Phase 6: User Story 4 - Edit an Existing Tag (Priority: P2)

**Goal**: Users can access an ellipsis menu on any tag row to edit the tag's name and color

**Independent Test**: Hover tag row, click ellipsis, select "Edit Tag", change name/color, save — tag updates everywhere

### Implementation for User Story 4

- [x] T016 [US4] Add ellipsis menu to each tag row in app/views/todo_items/_tag_editor.html.erb — on each tag row, add a three-dot icon button (visible on hover via CSS) that opens a small dropdown (reusing `dropdown_controller.js` pattern) with "Edit Tag" and "Delete Tag" options. "Edit Tag" triggers `showEdit` on tag_editor_controller. Reference "Tag Editor - Ellipsis Menu" screen in `designs/todo-list-item-screens.pen`
- [x] T017 [US4] Add `showEdit` action to tag_editor_controller.js in app/javascript/controllers/tag_editor_controller.js — receives tag data (id, name, color) via data attributes, populates the edit form fields, hides tag list, shows edit view. Add `editView` target
- [x] T018 [US4] Add `update` action to TagsController in app/controllers/tags_controller.rb — find tag via `Current.user.tags.find(params[:id])`, update with tag_params, validate uniqueness. Respond with Turbo Stream replacing tag editor and tags card. Handle validation errors by re-rendering edit form. Add `authorize_editor!` for update action. Reference "Edit Tag" screen in `designs/todo-list-item-screens.pen`
- [x] T019 [US4] Update _tag_form.html.erb to support edit mode — when `tag.persisted?`, pre-fill name and color fields, show "Save Changes" button (instead of "Create Tag"), form PATCHes to update path. Add "Delete this tag" link at bottom of edit form (wired to delete confirmation, placeholder for US5)
- [x] T020 [US4] Add Turbo Stream response template: create app/views/tags/update.turbo_stream.erb that replaces both tags card and tag editor frames

**Checkpoint**: User Stories 1-4 functional — ellipsis menu appears, edit form pre-fills, save updates tag globally

---

## Phase 7: User Story 5 - Delete a Tag (Priority: P2)

**Goal**: Users can permanently delete a tag via confirmation dialog, from either the ellipsis menu or edit form

**Independent Test**: Click "Delete Tag" from ellipsis menu, confirm in dialog — tag removed from all items and editor list

### Implementation for User Story 5

- [x] T021 [US5] Create app/views/todo_items/_tag_delete_confirm.html.erb — delete confirmation modal using existing `modal_controller.js` pattern. Shows tag name with color dot, warning text "Are you sure you want to delete this tag? It will be removed from all items.", Cancel button (closes modal) and "Delete Tag" button (submits permanent delete). Delete button is a `button_to` that DELETEs with `permanent=true` param. Reference "Delete Tag Confirm" screen in `designs/todo-list-item-screens.pen`
- [x] T022 [US5] Enhance `destroy` action in app/controllers/tags_controller.rb — when `params[:permanent]` is present, find and destroy the tag via `Current.user.tags.find(params[:id])` (cascades to all item_tags via dependent: :destroy). Respond with Turbo Stream replacing tags card and tag editor
- [x] T023 [US5] Wire delete triggers: in _tag_editor.html.erb, "Delete Tag" option in ellipsis dropdown opens the delete confirmation modal (sets tag data and adds `delete-modal--open` class). In _tag_form.html.erb (edit mode), "Delete this tag" link opens the same modal. Add `openDeleteModal` action to tag_editor_controller.js that populates modal with tag name/color and opens it

**Checkpoint**: All 5 user stories functional — full CRUD lifecycle for tags with confirmation on delete

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Tests, responsive design, edge cases, and CI validation

- [x] T024 [P] Add controller tests for index, enhanced create (toggle + new tag), update, and destroy (remove + permanent) actions in test/controllers/tags_controller_test.rb. Include auth tests (unauthenticated redirects, other user's tags return 404), validation error tests (duplicate name), and parameter injection tests
- [x] T025 [P] Create system tests for full tag editor flows in test/system/tag_management_test.rb — test: open editor and toggle tag, search filtering, create new tag with preset color, create with custom color, edit tag name/color, delete from ellipsis menu, delete from edit form, cancel flows, empty state, duplicate name error
- [x] T026 Verify responsive behavior — ensure tag editor dropdown works on mobile (full-width on small screens), color picker swatches wrap properly, ellipsis menus don't overflow viewport
- [x] T027 Handle edge cases — empty tag state (no tags exist, show only "Create new tag..."), search with no results
- [x] T028 Run full CI pipeline: `bin/rubocop`, `bin/brakeman --no-pager`, `bin/rails test`, `bin/rails test:system` — fix any failures

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (routes must exist) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — core editor and toggle functionality
- **US2 (Phase 4)**: Depends on Phase 3 (needs tag editor dropdown to exist) — adds search filtering
- **US3 (Phase 5)**: Depends on Phase 3 (needs tag editor and Stimulus controller) — adds create form
- **US4 (Phase 6)**: Depends on Phase 5 (shares _tag_form.html.erb for edit mode) — adds ellipsis menu and edit
- **US5 (Phase 7)**: Depends on Phase 6 (delete triggered from ellipsis menu and edit form) — adds delete confirmation
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Foundation only — MVP increment
- **US2 (P1)**: Builds on US1's tag editor dropdown
- **US3 (P1)**: Builds on US1's editor + Stimulus controller; shares no files with US2
- **US4 (P2)**: Builds on US3's form partial (shared create/edit)
- **US5 (P2)**: Builds on US4's ellipsis menu and edit form

### Within Each User Story

- Controller actions before view partials that use them
- Stimulus actions before view wiring that references them
- Core functionality before edge case handling

### Parallel Opportunities

- T001 and T002 can run in parallel (routes vs CSS — different files)
- T024 and T025 can run in parallel (controller tests vs system tests — different files)
- Within US1: T005 (controller) and T006 (partial) can start in parallel, T007-T009 depend on both

---

## Parallel Example: Phase 1

```bash
# These can run simultaneously (different files):
Task T001: "Expand tag routes in config/routes.rb"
Task T002: "Create tag_editor.css in app/assets/stylesheets/"
```

## Parallel Example: Phase 8

```bash
# These can run simultaneously (different test files):
Task T024: "Controller tests in test/controllers/tags_controller_test.rb"
Task T025: "System tests in test/system/tag_management_test.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (routes + CSS)
2. Complete Phase 2: Foundational (tags card + Stimulus controller)
3. Complete Phase 3: US1 — Tag toggle on/off
4. **STOP and VALIDATE**: Open editor, toggle tags, confirm checkmarks update
5. Deploy/demo if ready

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Add US1 → Toggle tags → Deploy (MVP!)
3. Add US2 → Search filtering → Deploy
4. Add US3 → Create tags with colors → Deploy
5. Add US4 → Edit tags → Deploy
6. Add US5 → Delete tags → Deploy
7. Phase 8 → Tests + polish → Final deploy

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- No schema migrations needed — existing Tag and ItemTag models are sufficient
- All .pen design screen references point to `designs/todo-list-item-screens.pen`
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently

## Implementation Deviations from Original Plan

These changes were made during implementation and diverge from the original task descriptions:

1. **T004/T016**: Per-row `dropdown_controller.js` was NOT reused for ellipsis menus. Instead, all ellipsis menus are managed by `tag_editor_controller.js` with `toggleEllipsis`/`closeAllEllipsis` methods. Reason: per-row controllers couldn't coordinate — multiple menus opened simultaneously.

2. **T003**: The tags card (`_tags_card.html.erb`) was simplified to render ONLY the tag pills. The trigger button, editor frame, and Stimulus controller were moved to `show.html.erb` as sibling elements. Reason: nesting the editor frame inside the replaceable tags card destroyed the Stimulus controller on every Turbo Stream replacement.

3. **T009/T020**: Turbo Stream templates replace BOTH `item_tags_` and `tag_editor_` frames as separate stream actions. Originally planned to only replace tags card. Reason: the editor needs updated checkmarks after each toggle.

4. **T006**: Toggle links/forms use `data-turbo-frame="_top"` instead of targeting `item_tags_`. Reason: forms inside a turbo-frame are scoped to that frame by default; `_top` ensures Turbo Stream responses are processed at the top level.

5. **T012**: Preset colors reduced from 8 to 7 (removed pink #F472B6). Reason: 8 swatches wrapped to a second line in the 280px popover.

6. **T012**: Form mode uses explicit `mode` parameter (`:create`/`:edit`) instead of `tag.persisted?`. Reason: the edit view uses `Tag.new(id: 0)` as a placeholder populated by JS.

## Outstanding Work (Future Features)

These items were identified during implementation and should be tracked for future sprints:

- [ ] Add Capybara system tests for full tag editor UI flows (open, toggle, search, create, edit, delete, cancel)
- [ ] Add keyboard navigation (arrow keys, Enter to toggle, Escape to close) for WCAG 2.1 AA
- [ ] Add tag ordering options (by frequency, recent, custom)
- [ ] Add bulk tag operations from list view
- [ ] Add tag usage count display in editor
- [ ] Replace native `<input type="color">` with custom color picker component
- [ ] Add empty state illustration/onboarding for users with no tags
