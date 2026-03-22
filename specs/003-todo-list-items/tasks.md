# Tasks: TODO List Items Management

**Input**: Design documents from `/specs/003-todo-list-items/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/ui-contracts.md, quickstart.md

**Tests**: Included — constitution requires test coverage for all features and security tests for all controllers.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Install dependencies, create migrations, configure routes

- [x] T001 Install ActionText: run `bin/rails action_text:install` for rich text notes support
- [x] T002 Create migration `add_fields_to_todo_items` adding status (string, default "todo", not null), due_date (date, nullable), priority (string, default "none", not null), archived (boolean, default false, not null), assigned_to_user_id (integer, nullable, FK to users) to `todo_items` in `db/migrate/`
- [x] T003 [P] Create migration `add_fields_to_todo_sections` adding icon (string, nullable), archived (boolean, default false, not null) to `todo_sections` in `db/migrate/`
- [x] T004 [P] Create migration `create_checklist_items` with name (string, not null), completed (boolean, default false, not null), position (integer, default 0, not null), todo_item_id (integer, not null, FK) in `db/migrate/`
- [x] T005 [P] Create migration `create_tags_and_item_tags` with tags table (name string not null, color string nullable, user_id integer not null FK) and item_tags join table (todo_item_id, tag_id, unique index) in `db/migrate/`
- [x] T005a [P] Create migration `create_comments` with body (text, not null), todo_item_id (integer, not null, FK), user_id (integer, not null, FK), timestamps in `db/migrate/`
- [x] T006 Run `bin/rails db:migrate` to apply all migrations
- [x] T007 Update routes in `config/routes.rb`: nest `todo_items` and `todo_sections` resources under `todo_lists` with member actions (toggle, archive, move, copy) and collection actions (reorder). Add nested routes for checklist_items, tags, and attachments under todo_items.

**Checkpoint**: Database schema updated, routes configured, ActionText installed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, controllers, and base partials that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 Update TodoItem model in `app/models/todo_item.rb`: add STATUSES and PRIORITIES constants, status/priority validations, has_many :checklist_items/:item_tags/:tags/:comments associations, belongs_to :assigned_to (User, optional), has_rich_text :notes, has_many_attached :files, scopes (active, completed, incomplete, overdue, by_position), business methods (toggle_completion!, archive!, overdue?, due_date_style), default_scope update to filter archived, completion/status sync callbacks
- [x] T009 [P] Update TodoSection model in `app/models/todo_section.rb`: add icon field, archived boolean, active scope, archive! method (archives section + all items), item_count method
- [x] T010 [P] Create ChecklistItem model in `app/models/checklist_item.rb`: belongs_to :todo_item, validations (name presence/length, position numericality), default_scope order by position
- [x] T011 [P] Create Tag model in `app/models/tag.rb`: belongs_to :user, has_many :item_tags/:todo_items, validations (name presence/length/uniqueness scoped to user_id case-insensitive)
- [x] T012 [P] Create ItemTag model in `app/models/item_tag.rb`: belongs_to :todo_item, belongs_to :tag, uniqueness validation on [todo_item_id, tag_id]
- [x] T012a [P] Create Comment model in `app/models/comment.rb`: belongs_to :todo_item, belongs_to :user, validations (body presence, length max 2000), default_scope order(created_at: :asc)
- [x] T013 Update TodoList model in `app/models/todo_list.rb`: update associations to use active scope on todo_items and todo_sections where appropriate
- [x] T014 Create TodoItemsController in `app/controllers/todo_items_controller.rb`: layout "app", before_action :set_todo_list (scoped to Current.user), before_action :set_todo_item, basic CRUD actions (show, create, update, destroy), strong params excluding todo_list_id/user_id
- [x] T015 [P] Create TodoSectionsController in `app/controllers/todo_sections_controller.rb`: layout "app", before_action :set_todo_list (scoped to Current.user), before_action :set_todo_section, basic CRUD actions (create, update, destroy), strong params
- [x] T016 [P] Write TodoItem model tests in `test/models/todo_item_test.rb`: test new validations (status inclusion, priority inclusion), scopes (active, completed, incomplete, overdue), business methods (toggle_completion!, archive!, overdue?, due_date_style), completion/status sync
- [x] T017 [P] Write TodoSection model tests in `test/models/todo_section_test.rb`: test icon field, archived scope, archive! method cascading to items
- [x] T018 [P] Write ChecklistItem model tests in `test/models/checklist_item_test.rb`: test validations, associations, ordering
- [x] T019 [P] Write Tag model tests in `test/models/tag_test.rb`: test validations, case-insensitive uniqueness scoped to user

**Checkpoint**: Foundation ready — models extended, controllers created, model tests passing. User story implementation can now begin.

---

## Phase 3: Core List View + Toggle + Security (US2, US6, US15) — Priority: P1 🎯 MVP

**Goal**: Display the TODO list detail view with items, sections, completion toggle, and full security. This is the primary screen users interact with daily.

**Independent Test**: Navigate to a populated TODO list, verify items and sections display with correct badges/indicators, toggle item completion, verify authorization prevents cross-user access.

### Tests for Phase 3

- [x] T020 [P] [US15] Write authentication tests in `test/controllers/todo_items_controller_test.rb`: test unauthenticated redirect for all actions (show, create, update, destroy, toggle, archive, move, copy, reorder)
- [x] T021 [P] [US15] Write authorization tests in `test/controllers/todo_items_controller_test.rb`: test accessing other user's items returns 404, index isolation, parameter injection (todo_list_id ignored)
- [x] T022 [P] [US15] Write authentication and authorization tests in `test/controllers/todo_sections_controller_test.rb`: unauthenticated redirects, cross-user 404s for all actions
- [x] T023 [P] [US6] Write toggle completion tests in `test/controllers/todo_items_controller_test.rb`: test toggle PATCH changes completed state, syncs status field, returns Turbo Stream response
- [x] T024 [P] [US2] Write system test for list detail view in `test/system/todo_items_test.rb`: test items display with names/badges, sections display with headers/counts, completed items show checkmark and reduced opacity

### Implementation for Phase 3

- [x] T025 [US2] Create `_todo_item.html.erb` partial in `app/views/todo_lists/`: item row with drag handle (grip-vertical), checkbox (circle), title (clickable link to detail), optional due badge (color-coded), optional avatar, optional priority dot. Wrap in Turbo Frame `dom_id(item)`. Match design from node `nGCDe`.
- [x] T026 [P] [US2] Create `_todo_item_completed.html.erb` partial in `app/views/todo_lists/`: completed variant with teal checkmark (circle-check filled), reduced opacity (0.5), muted title. Match design completed items.
- [x] T027 [US2] Create `_section.html.erb` partial in `app/views/todo_lists/`: section wrapper with header (drag handle, chevron, icon, name, item count badge, "Add item" button, ellipsis menu trigger) and collapsible items container. Wrap in Turbo Frame `dom_id(section)`. Match design from node `nGCDe`.
- [x] T028 [P] [US2] Create `_empty_section.html.erb` partial in `app/views/todo_lists/`: empty state hint ("No items yet — click Add item to get started") with icon. Match design from node `QBfz6`.
- [x] T029 [US2] Overhaul `app/views/todo_lists/show.html.erb`: update header to match design (back button, list emoji + title + edit pencil, "Add Section" button + purple "Add Item" button), display unsectioned items under "Items without section" header using `_todo_item` partials, render sections using `_section` partial, keep empty list slate for no items/sections.
- [x] T030 [US2] Update TodoListsController show action in `app/controllers/todo_lists_controller.rb`: eager-load todo_items and todo_sections with active scope, separate unsectioned items, pass sections ordered by position.
- [x] T031 [US6] Add `toggle` action to TodoItemsController in `app/controllers/todo_items_controller.rb`: PATCH toggles completed state (calls toggle_completion!), responds with turbo_stream replacing item partial (swaps between _todo_item and _todo_item_completed).
- [x] T032 [US6] Add Stimulus controller `item_checkbox_controller.js` in `app/javascript/controllers/`: target checkbox element, toggle action sends PATCH to toggle URL via fetch with Turbo Stream accept header. Add CSS transition for opacity change on completion.
- [x] T033 [US2] Add CSS for item rows, section headers, due badges, priority dots, completed items, and unsectioned header in `app/assets/stylesheets/todo_lists.css`. Match design tokens: item row height 44px, corner radius 12px, gap 12px, section header with colored left accent. Due badge colors: overdue #FEE2E2/#991B1B, upcoming #FEF3C7/#92400E, future #DBEAFE/#1E40AF, far-future #D1FAE5/#065F46.
- [x] T034 [US2] Add `section_collapse_controller.js` Stimulus controller in `app/javascript/controllers/`: toggle target for items container (slide up/down with height transition), rotate chevron icon 90deg on collapse. CSS transitions for smooth animation.

**Checkpoint**: List detail view displays items and sections with all badges, completion toggle works, security tests pass. MVP is functional.

---

## Phase 4: Inline Item Creation (US1) — Priority: P1

**Goal**: Users can rapidly create items inline with Enter-to-save-and-continue flow.

**Independent Test**: Click "Add Item", type a name, press Enter — item appears in list, new input ready for next item. Press Esc to cancel.

### Tests for Phase 4

- [x] T035 [P] [US1] Write controller tests for create action in `test/controllers/todo_items_controller_test.rb`: test POST creates item with name, responds with Turbo Stream, validates name presence, assigns to correct section (or unsectioned), ignores todo_list_id injection
- [x] T036 [P] [US1] Write system test for inline creation in `test/system/todo_items_test.rb`: test Add Item button shows input, Enter saves and shows new input, Esc cancels, empty name doesn't create item

### Implementation for Phase 4

- [x] T037 [US1] Create `_inline_item_input.html.erb` partial in `app/views/todo_lists/`: active input row with purple border and shadow, checkbox placeholder (empty circle), text input field (autofocus), keyboard hints ("Enter" badge + "to save", "Esc" badge + "to cancel"). Match design from node `Md812`.
- [x] T038 [US1] Create `_quick_actions.html.erb` partial in `app/views/todo_lists/`: quick action bar below input with Assign (user-plus icon), Due date (calendar icon), Priority (flag icon) buttons as pill-shaped bordered buttons. Match design from node `Md812`.
- [x] T039 [US1] Create `inline_item_controller.js` Stimulus controller in `app/javascript/controllers/`: connect auto-focuses input, keydown handler for Enter (POST via fetch to create endpoint with Turbo Stream accept header, on success server replaces input + prepends new item), keydown handler for Esc (remove input row without server call). Values: listId, sectionId (optional).
- [x] T040 [US1] Implement create action in TodoItemsController `app/controllers/todo_items_controller.rb`: accept turbo_stream format, on success respond with turbo_stream.prepend (new item partial) + turbo_stream.replace (reset input for next item), on failure respond with turbo_stream.replace (input with error state). Set position to 0 (prepend) and shift existing positions.
- [x] T041 [US1] Wire "Add Item" button in show.html.erb and section headers: clicking inserts `_inline_item_input` partial via Turbo Frame or JavaScript DOM insertion. "Add Item" in top bar adds to unsectioned area, "Add item" in section header adds within that section.
- [x] T042 [US1] Add CSS for active input row (purple border 2px, border-radius 14px, box-shadow purple glow, height 48px), keyboard hint badges (zinc-100 bg, rounded, small text), quick actions bar (gap 8px, pill buttons with border). Add fadeSlideIn animation for newly created items.

**Checkpoint**: Users can rapidly create items with Enter-to-continue flow. Quick action buttons visible but full functionality comes in Phase 8.

---

## Phase 5: Inline Section Creation (US3) — Priority: P1

**Goal**: Users can create sections inline with icon picker.

**Independent Test**: Click "Add Section", type a name, optionally select an icon, press Enter — section appears with empty state.

### Tests for Phase 5

- [x] T043 [P] [US3] Write controller tests for section create action in `test/controllers/todo_sections_controller_test.rb`: test POST creates section with name and optional icon, responds with Turbo Stream, validates name presence
- [x] T044 [P] [US3] Write system test for section creation in `test/system/todo_items_test.rb`: test Add Section button shows input, icon picker works, Enter creates section with empty hint

### Implementation for Phase 5

- [x] T045 [US3] Create `_inline_section_input.html.erb` partial in `app/views/todo_lists/`: active section input row with icon picker trigger (current icon + chevron), text input (autofocus), keyboard hint ("Enter to create"). Include `wa-dropdown` with icon grid for icon selection. Match design from node `kxC0I`.
- [x] T046 [US3] Create `inline_section_controller.js` Stimulus controller in `app/javascript/controllers/`: connect auto-focuses input, keydown Enter handler (POST via fetch to sections create endpoint), keydown Esc handler (remove input), selectIcon action (set selected icon value and update icon display via wa-dropdown wa-select event). Values: listId.
- [x] T047 [US3] Implement create action in TodoSectionsController `app/controllers/todo_sections_controller.rb`: accept turbo_stream format, on success respond with turbo_stream.append (new section partial with empty state) + turbo_stream.remove (inline input). Set position based on existing section count.
- [x] T048 [US3] Wire "Add Section" button in show.html.erb top bar: clicking appends `_inline_section_input` partial below existing content.
- [x] T049 [US3] Add CSS for inline section input (icon picker trigger, icon grid dropdown styling, section creation animation). Match design icon grid layout (5 icons per row, 40px button size).

**Checkpoint**: Users can create sections with icons. Sections display with empty state hint and "Add item" button.

---

## Phase 6: Context Menu Actions — Edit & Delete (US4, US13) — Priority: P2

**Goal**: Users can edit items/sections inline and delete them via context menus.

**Independent Test**: Right-click or click ellipsis on item/section, select Edit to modify name, select Delete to remove with confirmation.

### Tests for Phase 6

- [x] T050 [P] [US4] Write controller tests for update actions in `test/controllers/todo_items_controller_test.rb` and `test/controllers/todo_sections_controller_test.rb`: test PATCH updates name, validates presence, responds with Turbo Stream
- [x] T051 [P] [US13] Write controller tests for destroy actions in `test/controllers/todo_items_controller_test.rb` and `test/controllers/todo_sections_controller_test.rb`: test DELETE removes item/section, section delete cascades to items, responds with Turbo Stream remove

### Implementation for Phase 6

- [x] T052 [US4] Create `_item_context_menu.html.erb` partial in `app/views/todo_lists/`: `wa-dropdown` with `wa-dropdown-item` elements for Edit, Move..., Copy..., divider, Archive, Delete (variant="danger"), divider, Insert a to-do. Match design from node `9xhXA`.
- [x] T053 [P] [US4] Create `_section_context_menu.html.erb` partial in `app/views/todo_lists/`: `wa-dropdown` with items for Edit, Move..., Copy..., divider, New list from group, divider, Archive group, Delete group (variant="danger"), divider, Insert a to-do. Match design from node `Df59j`.
- [x] T054 [US4] Create `context_menu_controller.js` Stimulus controller in `app/javascript/controllers/`: listen for `wa-select` event on dropdown, dispatch actions based on `event.detail.item.value`. Handle: edit (toggle inline editing on item/section name), archive (PATCH archive endpoint via fetch), delete (open wa-dialog confirmation), insertTodo (insert inline item input at position). Move and Copy dispatch to respective modals (implemented in Phase 14).
- [x] T055 [US4] Implement update actions in TodoItemsController and TodoSectionsController: accept turbo_stream format, respond with turbo_stream.replace updating the item/section partial with new values.
- [x] T056 [US13] Implement destroy actions in TodoItemsController and TodoSectionsController: accept turbo_stream format, respond with turbo_stream.remove. Section destroy cascades to all contained items. Add wa-dialog confirmation partial for delete confirmation.
- [x] T057 [US4] Add `archive` action to TodoItemsController and TodoSectionsController: PATCH sets archived flag, responds with turbo_stream.remove (hides from view). Section archive cascades to all items.
- [x] T058 [US4] Add inline editing behavior: context_menu_controller edit action replaces item title/section name with an input field, Enter saves (PATCH), Esc cancels. Use Turbo Frame for seamless update.
- [x] T059 [US4] Add CSS for context menu positioning, inline edit state (input replaces title text), delete confirmation dialog styling. Add fadeOut animation for deleted/archived items.

**Checkpoint**: Context menus work for items and sections. Users can edit names inline and delete with confirmation.

---

## Phase 7: Drag & Drop Reordering (US5) — Priority: P2

**Goal**: Users can reorder items and sections via drag-and-drop with fun animations.

**Independent Test**: Drag an item by its grip handle to a new position, verify order persists after page reload. Drag between sections.

### Tests for Phase 7

- [x] T060 [P] [US5] Write controller tests for reorder action in `test/controllers/todo_items_controller_test.rb`: test PATCH reorder updates positions, supports moving between sections, validates ownership
- [x] T061 [P] [US5] Write controller tests for section reorder in `test/controllers/todo_sections_controller_test.rb`: test PATCH reorder updates section positions

### Implementation for Phase 7

- [x] T062 [US5] Create `drag_reorder_controller.js` Stimulus controller in `app/javascript/controllers/`: dragstart (add dragging class with rotation/shadow/purple border, show wa-tooltip hint), dragover (calculate drop position, show insertion indicator line, prevent default), dragend (remove all effects), drop (extract new position + section_id, send PATCH to reorder endpoint via fetch with Turbo Stream). Support dragging items within sections, between sections, and into/out of unsectioned area. Support dragging section headers to reorder entire sections.
- [x] T063 [US5] Add `reorder` collection action to TodoItemsController in `app/controllers/todo_items_controller.rb`: accept `{ id, position, section_id }` params, update item position and section assignment in a transaction, recalculate positions for affected items, respond with turbo_stream updates.
- [x] T064 [US5] Add `reorder` collection action to TodoSectionsController in `app/controllers/todo_sections_controller.rb`: accept `{ id, position }` params, update section position in a transaction, recalculate positions, respond with turbo_stream.
- [x] T065 [US5] Add `draggable="true"` and drag controller data attributes to `_todo_item.html.erb`, `_todo_item_completed.html.erb`, and `_section.html.erb` partials. Add drag handle styling.
- [x] T066 [US5] Add CSS for drag effects: `.todo-item--dragging` (transform: rotate(-1deg), box-shadow with purple glow, border 2px solid purple, elevated z-index), `.drop-indicator` (2px purple line between items), `.drag-hint` tooltip (dark bg, white text, rounded, shadow). Add spring-like ease transition for drop settlement. Match design from node `mg9id`.

**Checkpoint**: Items and sections can be reordered via drag-and-drop with smooth animations. Order persists across page reloads.

---

## Phase 8: Due Date & Priority (US10) — Priority: P2

**Goal**: Users can set due dates and priorities on items, displayed as color-coded badges.

**Independent Test**: Set a due date and priority on an item via quick actions during creation or via item detail, verify badges display correctly in list view.

### Tests for Phase 8

- [x] T067 [P] [US10] Write controller tests for item update with due_date and priority in `test/controllers/todo_items_controller_test.rb`: test PATCH with due_date/priority fields, verify Turbo Stream response updates badges
- [x] T068 [P] [US10] Write model tests for due_date_style in `test/models/todo_item_test.rb`: test overdue returns "danger", upcoming (0-3 days) returns "warning", future (4-14 days) returns "info", far-future returns "success"

### Implementation for Phase 8

- [x] T069 [US10] Wire quick action buttons in `_quick_actions.html.erb`: "Due date" button opens a native date input (type="date") or wa-input date picker, "Priority" button opens a wa-dropdown with None/Low/Medium/High options. Values set during inline creation via hidden fields in the create form.
- [x] T070 [US10] Create `quick_actions_controller.js` Stimulus controller in `app/javascript/controllers/`: setDueDate action (show/toggle date input, update hidden field), setPriority action (wa-dropdown with priority options, update hidden field), assign action (single-user stub — show current user avatar).
- [x] T071 [US10] Update TodoItemsController create and update actions to accept due_date and priority params in strong params.
- [x] T072 [US10] Update `_todo_item.html.erb` to render due date badge with color-coded styling (overdue/upcoming/future/far-future) and priority dot with correct color (none=hidden, low=teal, medium=orange, high=red). Use `item.due_date_style` helper method.
- [x] T073 [US10] Add CSS for due date badge color variants (`.due-badge--danger`, `.due-badge--warning`, `.due-badge--info`, `.due-badge--success`) and priority dot colors (`.priority-dot--low`, `.priority-dot--medium`, `.priority-dot--high`). Add subtle pulse animation on overdue badges.

**Checkpoint**: Due dates and priorities display correctly in list view with proper color coding.

---

## Phase 9: Item Detail View (US7) — Priority: P2

**Goal**: Users can click an item to view its full detail page with two-column layout.

**Independent Test**: Click an item title in the list, navigate to detail page showing header, status, metadata, and action buttons.

### Tests for Phase 9

- [x] T074 [P] [US7] Write controller tests for show action in `test/controllers/todo_items_controller_test.rb`: test GET renders item detail, test Mark Complete action, test Delete action
- [x] T075 [P] [US7] Write system test for item detail navigation in `test/system/todo_items_test.rb`: test clicking item navigates to detail, test status selector changes status, test Mark Complete button

### Implementation for Phase 9

- [x] T076 [US7] Create `app/views/todo_items/show.html.erb`: two-column layout with sidebar (reuse `_sidebar` partial), top bar (back button, list emoji + title + edit pencil, Add Section + Add Item buttons), left column (item header with status/priority badges, title h1 28px bold, meta row with created date + section, notes section placeholder, checklist section placeholder, attachments section placeholder, comments section placeholder), right column (status card, assignees card, due date card, notify card, tags card, actions card). Match design from node `sogSu`.
- [x] T077 [US7] Create `_status_sidebar.html.erb` partial in `app/views/todo_items/`: status selector card with Todo/In Progress/Done buttons (selectable, active state highlighted), "Mark Complete" button (green/teal, prominent), "Delete Item" button (red text). Status change sends PATCH via Turbo Frame.
- [x] T078 [US7] Implement show action in TodoItemsController: load item with associations (checklist_items, tags, comments, rich_text_notes, files, assigned_to), set @todo_list and @sidebar_lists.
- [x] T079 [US7] Add status change handling: clicking a status button sends PATCH to update action with new status value, responds with Turbo Frame replacing the status card. Sync completed field when status changes to/from "done".
- [x] T080 [US7] Add CSS for item detail layout: two-column flexbox (left flexible, right 280px fixed), item header (28px title, status/priority badges as colored pills), meta row (12px text, gray), divider lines, status card (segmented button group), action buttons (Mark Complete green gradient, Delete red text). Match design from node `sogSu`.
- [x] T080a [US7] Create `_assignees_card.html.erb` partial in `app/views/todo_items/`: single-user stub showing "Assigned to" label with add button (plus icon), current user displayed as assignee (avatar circle with initials + name) when assigned. Clicking add assigns the current user via PATCH. Uses `assigned_to_user_id` on TodoItem. Match design from node `sogSu`.
- [x] T080b [US7] Create `_notify_card.html.erb` partial in `app/views/todo_items/`: single-user stub showing "Notify on Complete" label with add button, current user displayed when added. Visual stub only — no notification system built. Match design from node `sogSu`.
- [x] T080c [US7] Create `_comments_section.html.erb` partial in `app/views/todo_items/`: single-user comments stub with header (message-circle icon, "Comments" title, count badge), comments list (current user avatar + body text + timestamp for each comment), comment input row (user avatar + "Write a comment..." placeholder input + send button). POST to create comment, Turbo Stream appends new comment. Match design from node `sogSu`.
- [x] T080d [US7] Add CSS for assignees card (avatar list, add button), notify card (person list), and comments section (comment bubbles, input row, send button styling). Match design from node `sogSu`.

**Checkpoint**: Users can navigate to item detail, view all metadata, change status, assign to self, add comments, and delete items.

---

## Phase 10: Item Notes with ActionText (US8) — Priority: P3

**Goal**: Users can add and edit rich text notes on TODO items using Trix editor.

**Independent Test**: Open item detail, click edit on Notes section, type formatted content with bullets, save and verify rendered HTML displays correctly.

### Tests for Phase 10

- [x] T081 [P] [US8] Write controller tests for updating notes in `test/controllers/todo_items_controller_test.rb`: test PATCH with notes rich text content via ActionText

### Implementation for Phase 10

- [x] T082 [US8] Add `has_rich_text :notes` to TodoItem model in `app/models/todo_item.rb`
- [x] T083 [US8] Create `_notes_section.html.erb` partial in `app/views/todo_items/`: Turbo Frame wrapping notes section with header (file-text icon, "Notes" title, edit pencil button), view mode (rendered rich text content), edit mode (hidden by default, Trix editor via `form.rich_text_area :notes`). Match design from node `sogSu`.
- [x] T084 [US8] Create `notes_editor_controller.js` Stimulus controller in `app/javascript/controllers/`: edit action (show Trix editor, hide rendered view), save action (submit form via Turbo Frame, swap back to view mode), cancel action (hide editor, show view).
- [x] T085 [US8] Update TodoItemsController update action to accept notes via ActionText strong params (`:notes` in permitted params).
- [x] T086 [US8] Add CSS for notes section: rendered content styling (prose-like typography, bullet list styling), Trix editor customization (match app theme, border radius, focus ring color), edit/save/cancel button positioning.

**Checkpoint**: Notes section works with Trix rich text editing, content persists and renders formatted.

---

## Phase 11: Item Checklist (US9) — Priority: P3

**Goal**: Users can create and manage checklists within TODO items with individual completion tracking.

**Independent Test**: Open item detail, add checklist items, toggle their completion, verify progress badge updates.

### Tests for Phase 11

- [x] T087 [P] [US9] Write controller tests for checklist CRUD in a new `test/controllers/checklist_items_controller_test.rb`: test create, toggle, destroy actions with Turbo Stream responses and authorization

### Implementation for Phase 11

- [x] T088 [US9] Create ChecklistItemsController in `app/controllers/checklist_items_controller.rb`: nested under todo_items (scoped through Current.user.todo_lists → todo_item), create action (POST, Turbo Stream append), toggle action (PATCH, Turbo Stream replace), destroy action (DELETE, Turbo Stream remove). Strong params for name only.
- [x] T089 [US9] Create `_checklist_section.html.erb` partial in `app/views/todo_items/`: Turbo Frame wrapping checklist with header (square-check icon, "Checklist" title, progress badge "3/5", add button), checklist items list (each: checkbox + name, done items with strikethrough), inline input for adding new items (Enter to add). Match design from node `sogSu`.
- [x] T090 [US9] Create `checklist_controller.js` Stimulus controller in `app/javascript/controllers/`: add action (Enter key in input, POST via fetch), toggle action (click checkbox, PATCH toggle via fetch), remove action (click x button, DELETE via fetch). All responses as Turbo Streams.
- [x] T091 [US9] Add CSS for checklist items: checkbox styling (matching app theme), done item strikethrough + muted color, progress badge (purple bg, white text), add input styling, item hover state.

**Checkpoint**: Checklists work with add, toggle, and remove functionality. Progress badge tracks completion.

---

## Phase 12: Item Tags (US11) — Priority: P3

**Goal**: Users can add and remove tags on TODO items for categorization.

**Independent Test**: Open item detail, type a tag name, press Enter to add, verify tag pill appears, click X to remove.

### Tests for Phase 12

- [x] T092 [P] [US11] Write controller tests for tag create/destroy in a new `test/controllers/tags_controller_test.rb`: test adding tag to item, removing tag, autocomplete existing tags, authorization

### Implementation for Phase 12

- [x] T093 [US11] Create TagsController in `app/controllers/tags_controller.rb` (nested under todo_items): create action (find or create tag by name for current user, create item_tag association, Turbo Stream append), destroy action (remove item_tag, Turbo Stream remove). Accept name param.
- [x] T094 [US11] Create `_tags_card.html.erb` partial in `app/views/todo_items/`: Turbo Frame wrapping tags card with "Tags" label, tag pills row (each: colored pill with name + X remove button), add tag input (type to search/create). Match design from node `sogSu` — tags shown as "Design", "Urgent", "Frontend" colored pills.
- [x] T095 [US11] Create `tag_manager_controller.js` Stimulus controller in `app/javascript/controllers/`: add action (Enter in input, POST via fetch), remove action (click X, DELETE via fetch), search action (input event, filter/autocomplete existing user tags).
- [x] T096 [US11] Add CSS for tag pills (colored backgrounds, rounded, small text, X button), tag input (inline with pills), autocomplete dropdown styling.

**Checkpoint**: Tags work with add, remove, and autocomplete. Colored pills display in item detail.

---

## Phase 13: Item Attachments (US12) — Priority: P3

**Goal**: Users can attach files to TODO items and view them as file cards.

**Independent Test**: Open item detail, upload a file via the upload button, verify file card appears with name and icon.

### Tests for Phase 13

- [x] T097 [P] [US12] Write controller tests for attachment upload/delete in a new `test/controllers/attachments_controller_test.rb`: test file upload creates attachment, delete removes it, authorization scoping

### Implementation for Phase 13

- [x] T098 [US12] Create AttachmentsController in `app/controllers/attachments_controller.rb` (nested under todo_items): create action (attach file via Active Storage, Turbo Stream append file card), destroy action (purge attachment, Turbo Stream remove). Validate file size (max 10MB).
- [x] T099 [US12] Create `_attachments_section.html.erb` partial in `app/views/todo_items/`: Turbo Frame wrapping attachments with header (paperclip icon, "Attachments" title, count badge, upload button with cloud-upload icon), file cards grid (each: file type icon + filename + file size). Upload button triggers hidden file input. Match design from node `sogSu`.
- [x] T100 [US12] Add CSS for attachments grid (3-column layout), file cards (border, rounded, icon + text, hover state), upload button styling, count badge.

**Checkpoint**: File attachments work with upload and delete. File cards display in grid layout.

---

## Phase 14: Move & Copy Items (US14) — Priority: P3

**Goal**: Users can move and copy items between sections via context menu actions.

**Independent Test**: Right-click an item, select Move, choose a destination section, verify item moves. Select Copy, verify duplicate appears at destination.

### Tests for Phase 14

- [x] T101 [P] [US14] Write controller tests for move and copy actions in `test/controllers/todo_items_controller_test.rb`: test move changes section_id and position, test copy creates duplicate in target section, test authorization

### Implementation for Phase 14

- [x] T102 [US14] Implement `move` member action in TodoItemsController `app/controllers/todo_items_controller.rb`: accept target_section_id (nil for unsectioned) and target_position params, update item's section and position in transaction, recalculate positions, respond with Turbo Stream (remove from old location, append to new).
- [x] T103 [US14] Implement `copy` member action in TodoItemsController: duplicate item attributes (name, due_date, priority, status) to target section/position, respond with Turbo Stream append.
- [x] T104 [US14] Implement `move` action in TodoSectionsController: accept target_position, update section position in transaction.
- [x] T105 [US14] Create move/copy destination picker: `wa-dialog` with list of sections (+ "Items without section" option) as selectable items. Opened by context_menu_controller when Move/Copy actions are selected. Include section icons and item counts.
- [x] T106 [US14] Update `context_menu_controller.js` to wire Move and Copy actions to open the destination picker dialog, capture selection, and send appropriate PATCH/POST request.
- [x] T107 [US14] Add CSS for destination picker dialog: section list items with icons, selected state, confirm/cancel buttons.

**Checkpoint**: Move and copy work via context menu with destination picker dialog.

---

## Phase 15: Polish & Cross-Cutting Concerns

**Purpose**: Animations, responsive design, accessibility, and quality assurance

- [x] T108 [P] Add micro-animations throughout in `app/assets/stylesheets/todo_lists.css`: fadeSlideIn for new items, checkPulse for completion toggle, dragLift for drag start, spring-ease for drop settlement, fadeOut for delete/archive, section collapse slide transition, context menu hover highlights
- [x] T109 [P] Add responsive CSS for mobile in `app/assets/stylesheets/todo_lists.css`: single-column layout at 768px breakpoint, sidebar hidden on mobile, full-width items, touch-friendly tap targets (min 44px), context menus as bottom sheets on mobile
- [x] T110 [P] Update `app/views/todo_lists/_sidebar.html.erb`: ensure item counts reflect active (non-archived) items, completion percentage includes new status/priority data
- [x] T111 Run full test suite: `bin/rails test` and `bin/rails test:system` — zero failures
- [x] T112 Run `bin/rubocop` — fix any offenses to zero
- [x] T113 Run `bin/brakeman --no-pager` — fix any warnings to zero
- [x] T114 Validate all views against design reference screens in `todo-list-item-screens.pen` using Pencil MCP screenshots — fix spacing, fonts, colors, and component sizes to match
- [x] T115 Update spec documents (spec.md, plan.md) with implementation learnings and design decisions discovered during development

---

## Phase 16: Copilot Code Review Fixes (2026-03-22)

**Purpose**: Fixes identified during Copilot PR code review rounds

### Round 1 (10 comments)

- [x] T116 Fix duplicate `dependent: :destroy` on `todo_sections` — remove from scoped association in `app/models/todo_list.rb`
- [x] T117 Fix CSS injection via `tag.color` — add hex format validation to `app/models/tag.rb`
- [x] T118 Fix duplicate DOM IDs in `_todo_item.html.erb`, `_todo_item_completed.html.erb`, `_section.html.erb` — remove inner div `id` attributes
- [x] T119 Fix archived sections not findable — use `all_todo_sections.find` in `app/controllers/todo_sections_controller.rb`
- [x] T120 Fix update action always using incomplete partial — select based on `completed?` in `app/controllers/todo_items_controller.rb`
- [x] T121 Fix "Delete group" missing `variant="danger"` in `app/views/todo_lists/_section_context_menu.html.erb`
- [x] T122 Fix section position using scoped count — use `all_todo_sections.count` in `app/controllers/todo_sections_controller.rb`

### Round 2 (20 comments)

- [x] T123 Fix context menu targets as siblings — wrap dropdown + forms in container div in `_item_context_menu.html.erb` and `_section_context_menu.html.erb`
- [x] T124 Fix `assigned_to_user_id` security — force to `Current.user.id` in `app/controllers/todo_items_controller.rb`
- [x] T125 Fix position shift including new item — shift BEFORE save in transaction in `app/controllers/todo_items_controller.rb`
- [x] T126 Fix `completion_percentage` including archived items — filter on `archived: false` in `app/models/todo_list.rb`
- [x] T127 Fix notes form Turbo response wrong on detail page — add `data: { turbo: false }` in `_notes_section.html.erb`
- [x] T128 Fix status buttons Turbo response on detail page — add `data: { turbo: false }` in `_status_sidebar.html.erb`
- [x] T129 Fix Mark Complete/Delete on detail page — add `data: { turbo: false }` in `app/views/todo_items/show.html.erb`
- [x] T130 Create `TagsController` in `app/controllers/tags_controller.rb` with create/destroy actions
- [x] T131 Add case-insensitive unique index on tags `(user_id, lower(name))` via migration
- [x] T132 Fix `showPicker()` browser compat — wrap in feature detection in `quick_actions_controller.js`
- [x] T133 Remove `draggable="true"` from section header in `_section.html.erb`
- [x] T134 Add guard checks for missing targets in `context_menu_controller.js`
- [x] T135 Fix tag.color validation — tighten regex to 6-digit hex only in `app/models/tag.rb`

### Additional Implementation Fixes

- [x] T136 Fix inline item input position — render inside `#unsectioned-items` after header, not above page header
- [x] T137 Fix blank slate / content area toggle — always render both, use `display: none` for toggle
- [x] T138 Fix `turbo_frame` link navigation — add `data: { turbo_frame: "_top" }` to item title links
- [x] T139 Rewrite drag controller for turbo-frame compatibility — draggable on frames, cross-section drops
- [x] T140 Fix `button_to` with blocks — remove first string arg when using block form
- [x] T141 Fix inline section creation — use `fetch()` POST instead of `requestSubmit()` on non-form element
- [x] T142 Add section editing via context menu — inline edit with icon picker in `context_menu_controller.js`
- [x] T143 Create `ChecklistItemsController` with create/toggle/destroy actions
- [x] T144 Create `CommentsController` with create/destroy actions + comment route
- [x] T145 Create `AttachmentsController` with create/destroy actions
- [x] T146 Make Notes section functional with ActionText/Trix editor toggle
- [x] T147 Remove Add Section/Add Item buttons from item detail header
- [x] T148 Add delete (trash) button to list show header
- [x] T149 Fix system tests — sign-in helper events, delete test for new UI
- [x] T150 Clear bootsnap cache for stale schema resolution

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **Core List View (Phase 3)**: Depends on Foundational — this is the MVP
- **Inline Item Creation (Phase 4)**: Depends on Phase 3 (needs list view to render items into)
- **Inline Section Creation (Phase 5)**: Depends on Phase 3 (needs list view structure)
- **Edit & Delete (Phase 6)**: Depends on Phase 3 (needs items/sections to act on)
- **Drag & Drop (Phase 7)**: Depends on Phase 3 (needs items/sections to reorder)
- **Due Date & Priority (Phase 8)**: Depends on Phase 3 (needs item partials to display badges)
- **Item Detail View (Phase 9)**: Depends on Phase 3 (needs items to click into)
- **Notes (Phase 10)**: Depends on Phase 9 (needs item detail page)
- **Checklist (Phase 11)**: Depends on Phase 9 (needs item detail page)
- **Tags (Phase 12)**: Depends on Phase 9 (needs item detail page)
- **Attachments (Phase 13)**: Depends on Phase 9 (needs item detail page)
- **Move & Copy (Phase 14)**: Depends on Phase 6 (needs context menus)
- **Polish (Phase 15)**: Depends on all prior phases

### User Story Dependencies

```
Phase 1 (Setup)
  └── Phase 2 (Foundational)
       └── Phase 3 (US2+US6+US15 — Core View) 🎯 MVP
            ├── Phase 4 (US1 — Inline Items)
            ├── Phase 5 (US3 — Inline Sections)
            ├── Phase 6 (US4+US13 — Edit/Delete)
            │    └── Phase 14 (US14 — Move/Copy)
            ├── Phase 7 (US5 — Drag & Drop)
            ├── Phase 8 (US10 — Due Date/Priority)
            └── Phase 9 (US7 — Item Detail)
                 ├── Phase 10 (US8 — Notes)
                 ├── Phase 11 (US9 — Checklist)
                 ├── Phase 12 (US11 — Tags)
                 └── Phase 13 (US12 — Attachments)
```

### Within Each Phase

- Tests MUST be written and FAIL before implementation
- Models/migrations before controller actions
- Controller actions before view partials
- Partials before Stimulus controllers
- CSS last (needs DOM structure to style)

### Parallel Opportunities

- Phases 4, 5, 6, 7, 8 can run in parallel after Phase 3 completes
- Phases 10, 11, 12, 13 can run in parallel after Phase 9 completes
- Within each phase, tasks marked [P] can run in parallel
- All model tests (T016-T019) can run in parallel
- All auth/security tests (T020-T022) can run in parallel

---

## Parallel Examples

### Phase 2 — Foundational Models

```
# These model files are independent and can be created in parallel:
T008: Update TodoItem model in app/models/todo_item.rb
T009: Update TodoSection model in app/models/todo_section.rb
T010: Create ChecklistItem model in app/models/checklist_item.rb
T011: Create Tag model in app/models/tag.rb
T012: Create ItemTag model in app/models/item_tag.rb
```

### Phase 3 — Core View Partials

```
# These partials are independent files:
T025: Create _todo_item.html.erb
T026: Create _todo_item_completed.html.erb
T028: Create _empty_section.html.erb
```

### After Phase 3 — Parallel P2 Stories

```
# These phases have no dependencies on each other:
Phase 4 (Inline Items) — Developer A
Phase 5 (Inline Sections) — Developer A (after Phase 4)
Phase 6 (Edit/Delete) — Developer B
Phase 7 (Drag & Drop) — Developer C
Phase 8 (Due Date/Priority) — Developer B (after Phase 6)
```

---

## Implementation Strategy

### MVP First (Phase 3 Only)

1. Complete Phase 1: Setup (migrations, routes, ActionText)
2. Complete Phase 2: Foundational (models, controllers, tests)
3. Complete Phase 3: Core List View + Toggle + Security
4. **STOP and VALIDATE**: List displays items/sections with badges, toggle works, security passes
5. Deploy/demo if ready — this is a functional TODO list viewer

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Phase 3 (Core View) → Test → Deploy (MVP!)
3. Phase 4 (Inline Items) → Users can add items → Deploy
4. Phase 5 (Inline Sections) → Users can organize → Deploy
5. Phase 6 (Edit/Delete) → Users can manage → Deploy
6. Phase 7 (Drag & Drop) → Users can reorder → Deploy
7. Phase 8 (Due Date/Priority) → Users can track → Deploy
8. Phase 9 (Item Detail) → Rich item view → Deploy
9. Phases 10-13 (Notes/Checklist/Tags/Attachments) → Full detail → Deploy
10. Phase 14 (Move/Copy) → Advanced management → Deploy
11. Phase 15 (Polish) → Production-ready → Deploy

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each phase should be independently completable and testable
- Constitution requires tests for all features — tests are included in each phase
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All UI must be validated against `todo-list-item-screens.pen` design reference
- Web Awesome components: wa-dropdown, wa-dropdown-item, wa-dialog, wa-tooltip, wa-button, wa-icon, wa-input
- Font Awesome icons throughout (variant="thin" for list items)
- ActionText/Trix for notes (D1 in plan.md — Fizzy is NOT an editor)
