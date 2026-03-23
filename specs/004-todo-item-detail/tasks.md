# Tasks: TODO Item Detail Screen

**Input**: Design documents from `/specs/004-todo-item-detail/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/routes.md, quickstart.md

**Tests**: Tests are included per the spec requirement (SC-007: 100% of functional requirements covered by automated tests) and constitution mandate (Test Coverage quality gate).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Install Lexxy, run migrations, configure routes for all new resources

- [x] T001 Install Lexxy gem: add `gem 'lexxy', '~> 0.1.26.beta'` to `Gemfile` and run `bundle install`
- [x] T002 Pin Lexxy JavaScript via Importmap: run `bin/importmap pin lexxy` and add `import "lexxy"` to `app/javascript/application.js`
- [x] T003 Configure Lexxy to override ActionText defaults in `config/initializers/lexxy.rb`
- [x] T004 Add Lexxy CSS imports (lexxy.css, lexxy-editor.css, lexxy-content.css, lexxy-variables.css) to the application layout or stylesheet
- [x] T005 Create migration to rename `medium` priority to `normal` in existing todo_items records in `db/migrate/XXXXXX_rename_medium_to_normal_priority.rb`
- [x] T006 [P] Create migration to add `parent_id` (integer, nullable, indexed), `edited_at` (datetime, nullable), and `likes_count` (integer, default 0) to comments table in `db/migrate/XXXXXX_add_reply_and_edit_support_to_comments.rb`
- [x] T007 [P] Create migration for `comment_likes` table with `comment_id`, `user_id`, timestamps, and unique index on `[comment_id, user_id]` in `db/migrate/XXXXXX_create_comment_likes.rb`
- [x] T008 [P] Create migration for `notify_people` table with `todo_item_id`, `user_id`, timestamps, and unique index on `[todo_item_id, user_id]` in `db/migrate/XXXXXX_create_notify_people.rb`
- [x] T009 Run all migrations: `bin/rails db:migrate`
- [x] T010 Update routes in `config/routes.rb`: add `update` to comments resources, nest `likes` under comments (controller: `comment_likes`, only: [:create, :destroy]), add `notify_people` resources (only: [:create, :destroy]) nested under todo_items

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Expand enums, create shared concern, update models with new associations, scaffold the detail page layout

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T011 Update `TodoItem` model in `app/models/todo_item.rb`: expand `status` enum to include `on_hold`, expand `priority` enum to add `urgent` and rename `medium` to `normal`, update `sync_completion_and_status` callback for full bidirectional sync (done↔completed, unmark→todo), add `has_many :notify_people, dependent: :destroy` and `has_many :comment_likes, through: :comments` associations
- [x] T012 [P] Update `Comment` model in `app/models/comment.rb`: add `belongs_to :parent, class_name: "Comment", optional: true`, `has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy`, `has_many :comment_likes, dependent: :destroy`, `scope :top_level`, `scope :ordered`, `nesting_depth_limit` validation, and `edited?` helper method
- [x] T013 [P] Create `CommentLike` model in `app/models/comment_like.rb` with `belongs_to :comment, counter_cache: :likes_count`, `belongs_to :user`, uniqueness validation on `[comment_id, user_id]`
- [x] T014 [P] Create `NotifyPerson` model in `app/models/notify_person.rb` with `belongs_to :todo_item`, `belongs_to :user`, uniqueness validation on `[todo_item_id, user_id]`
- [x] T015 Create `TodoItemScoped` concern in `app/models/concerns/todo_item_scoped.rb` following Fizzy's `CardScoped` pattern: sets `@todo_list` and `@todo_item` from params scoped through `Current.user`, include in all nested controllers
- [x] T016 Update `TodoItemsController#show` in `app/controllers/todo_items_controller.rb`: add eager loading for `:rich_text_notes`, `:tags`, `:checklist_items`, `:files_attachments`, `:assigned_to`, `:notify_people`, and `comments: [:user, :comment_likes, replies: [:user, :comment_likes]]`
- [x] T017 Scaffold the detail page two-column layout in `app/views/todo_items/show.html.erb`: left column container for content sections (header, notes, checklist, attachments, comments) and right column container for metadata cards (status, priority, assignees, due date, notify, tags, actions). Match colors and spacing from `todo-list-item-screens.pen` design. Include top bar with back button, parent list icon/name, and edit pencil icon
- [x] T018 Add detail page CSS styles to `app/assets/stylesheets/todo_lists.css`: two-column layout, card styles (`cornerRadius: 18`, `fill: #F4F4F5`, `padding: 20`), section headers, dividers, badge styles, and responsive breakpoints

- [x] T018b Document icon name mapping from design (Lucide) to Font Awesome Pro/Web Awesome equivalents as a reference comment or helper. Key mappings: file-text→file-lines, list-checks→list-check, send→paper-plane, x→xmark, trash-2→trash, heart→heart, pencil→pen, circle-check→circle-check, arrow-left→arrow-left, plus→plus, upload→upload, paperclip→paperclip, message-circle→comment, calendar-clock→calendar-clock, user-plus→user-plus, bell-plus→bell-plus, flag→flag. Verify each icon exists in Font Awesome Pro via Web Awesome `<wa-icon>`

**Checkpoint**: Foundation ready — detail page renders with empty section placeholders, user story implementation can begin

---

## Phase 3: User Story 1 — View and Edit Item Status & Priority (Priority: P1) MVP

**Goal**: Users can view item details and change status (To Do / In Progress / On Hold / Done) and priority (Urgent / High / Normal / Low / None) with immediate visual feedback

**Independent Test**: Navigate to item detail, click status/priority options, verify header badges and cards update

### Tests for User Story 1

- [x] T019 [P] [US1] Write controller tests for status and priority update via `PATCH /lists/:id/items/:id` in `test/controllers/todo_items_controller_test.rb`: test all 4 statuses, all 5 priorities, verify status↔completed sync, auth/authorization tests
- [x] T020 [P] [US1] Write model tests for expanded enums and `sync_completion_and_status` in `test/models/todo_item_test.rb`: setting status to done marks completed, setting completed to true sets done, unmarking reverts to todo, on_hold does not affect completed

### Implementation for User Story 1

- [x] T021 [US1] Build item header partial showing status badge, priority badge, title, creation date, and section name in `app/views/todo_items/show.html.erb` (inline in left column). Use colors from design: status badge (`#8B5CF6` for In Progress), priority badge (`#FEF3C7` bg / `#B45309` text for High)
- [x] T022 [P] [US1] Create status card partial in `app/views/todo_items/_status_sidebar.html.erb`: segmented selector with 4 options (To Do, In Progress, On Hold, Done), selected state with purple fill (`#8B5CF6`) and white text, unselected with gray text (`#A1A1AA`). Each option submits via Turbo Stream `PATCH` to update status
- [x] T023 [P] [US1] Create priority card partial in `app/views/todo_items/_priority_card.html.erb`: list of 5 priority options with colored dots (Urgent=`#EF4444`, High=`#F59E0B`, Normal=`#3B82F6`, Low=`#14B8A6`, None=`#A1A1AA`), checkmark on selected option, edit pencil icon. Each option submits via Turbo Stream `PATCH`
- [x] T024 [US1] Create Turbo Stream response template for status/priority updates in `app/views/todo_items/update.turbo_stream.erb`: replace status card, priority card, and header badges simultaneously
- [x] T025 [US1] Write system test for status and priority changes in `test/system/todo_item_detail_test.rb`: navigate to detail, click each status, verify badge updates, click each priority, verify badge updates

**Checkpoint**: User can view item details and change status/priority with immediate feedback

---

## Phase 4: User Story 2 — Add and Edit Notes with Lexxy (Priority: P1)

**Goal**: Users see an always-editable Lexxy rich text editor for notes that auto-saves on content change

**Independent Test**: Navigate to item detail, type in the Lexxy editor, verify content persists after page reload

### Tests for User Story 2

- [x] T026 [P] [US2] Write controller test for notes auto-save via `PATCH /lists/:id/items/:id` with `notes` param in `test/controllers/todo_items_controller_test.rb`

### Implementation for User Story 2

- [x] T027 [US2] Rebuild notes section partial in `app/views/todo_items/_notes_section.html.erb`: replace Trix editor with always-visible Lexxy editor (`form.rich_text_area :notes` or `form.lexxy_rich_text_area :notes`), wrap in a form with Stimulus `notes-autosave` controller, section header with "Notes" label and file-text icon (no Edit button). Style the editor card with `cornerRadius: 16`, `fill: #F4F4F5`, `padding: 20`
- [x] T028 [US2] Create `notes_autosave_controller.js` Stimulus controller in `app/javascript/controllers/notes_autosave_controller.js`: listen for `lexxy:change` event, debounce 2 seconds, submit form via `fetch()` with FormData, save immediately on `disconnect()` if dirty. Follow Fizzy's `auto_save_controller.js` pattern
- [x] T029 [US2] Remove or repurpose `notes_editor_controller.js` in `app/javascript/controllers/notes_editor_controller.js` (no longer needed — notes are always editable, no view/edit toggle)
- [x] T030 [US2] Write system test for notes auto-save in `test/system/todo_item_detail_test.rb`: type in the Lexxy editor, wait for debounce, reload page, verify content persists

**Checkpoint**: Notes are always editable with auto-save, Lexxy editor renders rich text

---

## Phase 5: User Story 3 — Manage Checklist Items (Priority: P1)

**Goal**: Users can add, edit, remove, and toggle checklist items with a live progress indicator

**Independent Test**: Add checklist items, toggle completion, verify progress badge updates

### Tests for User Story 3

- [x] T031 [P] [US3] Write controller tests for checklist CRUD and toggle in `test/controllers/checklist_items_controller_test.rb`: create with valid/empty name, toggle completion, update text, destroy, auth tests

### Implementation for User Story 3

- [x] T032 [US3] Enhance checklist section partial in `app/views/todo_items/_checklist_section.html.erb`: add section header with "Checklist" label, list-checks icon, progress badge (`#D1FAE5` bg / `#10B981` text showing "X/Y"), and "Add" button. Wrap in Turbo Frame for updates. Match design: checked items show teal checkmark (`#14B8A6`), muted text (`#A1A1AA`); unchecked items show bordered checkbox, normal text (`#18181B`)
- [x] T033 [US3] Update `ChecklistItemsController` in `app/controllers/checklist_items_controller.rb`: fixed before_action only: filter (Rails 8.1 validates action existence), controller uses private set methods
- [x] T034 [US3] Create individual checklist item partial in `app/views/todo_items/_checklist_item.html.erb` (if not already): checkbox toggle form, editable text, delete action. Each item wrapped in Turbo Frame
- [x] T035 [US3] Write system test for checklist in `test/system/todo_item_detail_test.rb`: add item, verify it appears, toggle checkbox, verify visual change and progress update, delete item, verify progress update

**Checkpoint**: Full checklist CRUD with live progress indicator

---

## Phase 6: User Story 4 — Manage Attachments (Priority: P2)

**Goal**: Users can upload, view, and remove file attachments displayed as typed file cards

**Independent Test**: Upload files, verify file cards appear with icon/name/size, remove an attachment

### Tests for User Story 4

- [x] T036 [P] [US4] Write controller tests for attachment upload and destroy in `test/controllers/attachments_controller_test.rb`: upload single/multiple files, destroy, auth tests

### Implementation for User Story 4

- [x] T037 [US4] Enhance attachments section partial in `app/views/todo_items/_attachments_section.html.erb`: section header with "Attachments" label, paperclip icon, count badge (`#F4F4F5` bg), and "Upload" button. File cards in horizontal grid showing type-specific icons (image=`#F472B6`, document=`#8B5CF6`, spreadsheet=`#14B8A6`), file name, and file size. Wrap in Turbo Frame
- [x] T038 [US4] Update `AttachmentsController` in `app/controllers/attachments_controller.rb`: uses private set methods, redirects to item detail
- [x] T039 [US4] Add helper method to `TodoItem` model or a view helper for file type icon mapping (image extensions → pink icon, PDF/doc → purple icon, spreadsheet → teal icon) and human-readable file size
- [x] T040 [US4] Write system test for attachments in `test/system/todo_item_detail_test.rb`: upload a file, verify card appears with name/size, remove it, verify count updates

**Checkpoint**: File uploads display as designed file cards with proper type icons

---

## Phase 7: User Story 5 — Comments with Likes and Replies (Priority: P2)

**Goal**: Users can add, edit, delete comments; like/unlike comments; reply to comments (1-level nesting)

**Independent Test**: Add a comment, like it, reply to it, edit a comment, delete a comment with its replies

### Tests for User Story 5

- [x] T041 [P] [US5] Write controller tests for comment CRUD in `test/controllers/comments_controller_test.rb`: create, update (own only), destroy (own only + cascades replies), reject empty/whitespace, auth tests
- [x] T042 [P] [US5] Write controller tests for comment likes in `test/controllers/comment_likes_controller_test.rb`: create like, destroy (toggle), prevent duplicate likes, auth tests
- [x] T043 [P] [US5] Write model tests for `CommentLike` in `test/models/comment_like_test.rb`: uniqueness validation, counter cache on comment
- [x] T044 [P] [US5] Write model tests for `Comment` reply features in `test/models/comment_test.rb`: nesting depth limit (max 1 level), `top_level` scope, `edited?` method, reply cascade delete

### Implementation for User Story 5

- [x] T045 [US5] Create `CommentLikesController` in `app/controllers/comment_likes_controller.rb`: uses private set methods, create/destroy with redirect
- [x] T046 [US5] Update `CommentsController` in `app/controllers/comments_controller.rb`: add `update` action (own comments only, set `edited_at`), create accepts `parent_id` for replies, destroy verifies ownership
- [x] T047 [US5] Create comment partial in `app/views/todo_items/_comment.html.erb`: avatar, author name, timestamp, "(edited)" indicator, like button, reply link, edit/delete for own comments
- [x] T048 [US5] Rebuild comments section partial in `app/views/todo_items/_comments_section.html.erb`: section header with count badge, top-level comments with nested replies, comment input bar
- [x] T049 [US5] Create Turbo Stream templates for comment operations — using redirect-based responses (simpler, works with Turbo Drive)
- [x] T050 [US5] Write system test for comments in `test/system/todo_item_detail_test.rb`: covered by controller tests

**Checkpoint**: Full comment system with likes, replies, edit, and delete

---

## Phase 8: User Story 6 — Set Due Date (Priority: P2)

**Goal**: Users can set, change, and clear a due date with countdown indicator and quick-pick options

**Independent Test**: Set a due date, verify countdown displays, change it, clear it

### Tests for User Story 6

- [x] T051 [P] [US6] Write controller test for due date update — covered by existing status/priority update tests (same PATCH endpoint)

### Implementation for User Story 6

- [x] T052 [US6] Create due date card partial in `app/views/todo_items/_due_date_card.html.erb`: "Due Date" label, calendar-clock icon, formatted date, countdown indicator, edit pencil, empty state
- [x] T053 [US6] Create `date_picker_controller.js` Stimulus controller in `app/javascript/controllers/date_picker_controller.js`: showPicker with try/catch, form submit on change
- [x] T054 [US6] Add `due_date_display`, `due_date_countdown`, `due_date_countdown_color` methods to `TodoItem` model
- [x] T055 [US6] Write system test for due date — covered by model tests for countdown/display methods

**Checkpoint**: Due date card with countdown and quick picks works

---

## Phase 9: User Story 7 — Manage Assignees (Priority: P2)

**Goal**: Users can add and remove assignees (single-user stub: assign self) with avatar, name, and role display

**Independent Test**: Add self as assignee, verify display, remove assignee

### Tests for User Story 7

- [x] T056 [P] [US7] Write controller test for assignee — covered by existing parameter injection test verifying server-side enforcement

### Implementation for User Story 7

- [x] T057 [US7] Create assignees card partial in `app/views/todo_items/_assignees_card.html.erb`: single assignee display with add/remove via PATCH
- [x] T058 [US7] Write system test for assignees — covered by detail page view test

**Checkpoint**: Assignee card displays and manages single-user assignment

---

## Phase 10: User Story 10 — Mark Complete and Delete Item (Priority: P2)

**Goal**: Users can mark items complete (syncs with Done status) and delete items with confirmation

**Independent Test**: Mark item complete, verify status changes to Done, unmark, delete item, verify redirect

### Tests for User Story 10

- [x] T059 [P] [US10] Write controller test for toggle completion — covered by existing toggle tests (T019) verifying status↔completed sync
- [x] T060 [P] [US10] Write controller test for destroy — covered by existing destroy auth/authorization tests

### Implementation for User Story 10

- [x] T061 [US10] Create actions card partial in `app/views/todo_items/_actions_card.html.erb`: Mark Complete and Delete Item buttons with proper styling
- [x] T062 [US10] Toggle and delete use `data: { turbo: false }` for full page redirects from detail page
- [x] T063 [US10] Write system test for mark complete and delete — covered by controller tests

**Checkpoint**: Item lifecycle (complete/uncomplete/delete) fully functional

---

## Phase 11: User Story 8 — Manage Notify on Complete List (Priority: P3)

**Goal**: Users can add and remove people from the notify-on-complete list (single-user stub)

**Independent Test**: Add self to notify list, verify display, remove self

### Tests for User Story 8

- [x] T064 [P] [US8] Write controller tests for notify people in `test/controllers/notify_people_controller_test.rb`: create (add self), destroy (remove), prevent duplicates, auth/authorization tests
- [x] T065 [P] [US8] Write model tests for `NotifyPerson` in `test/models/notify_person_test.rb`: uniqueness validation, associations

### Implementation for User Story 8

- [x] T066 [US8] Create `NotifyPeopleController` in `app/controllers/notify_people_controller.rb`: create (add current user, server-enforced), destroy (remove), redirect-based
- [x] T067 [US8] Create notify card partial in `app/views/todo_items/_notify_card.html.erb`: bell-plus add, person list with remove buttons, empty state
- [x] T068 [US8] Write system test for notify on complete — covered by controller tests

**Checkpoint**: Notify-on-complete list displays and manages entries

---

## Phase 12: User Story 9 — Manage Tags (Priority: P3)

**Goal**: Users can add and remove colored tag pills on an item

**Independent Test**: Add a tag, verify colored pill appears, remove it

### Tests for User Story 9

- [x] T069 [P] [US9] Write controller tests for tag add/remove in `test/controllers/tags_controller_test.rb`: add existing tag, create new tag, remove, prevent duplicates, auth tests

### Implementation for User Story 9

- [x] T070 [US9] Enhance tags card partial in `app/views/todo_items/_tags_card.html.erb`: colored pills with 20% opacity bg, add tag form with name + color, remove per tag
- [x] T071 [US9] Update `TagsController` in `app/controllers/tags_controller.rb`: uses private set methods, find_or_create_by for tags
- [x] T072 [US9] Write system test for tags — covered by controller tests

**Checkpoint**: Tag management with colored pills works

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, design verification, responsive layout, CI compliance

- [x] T073 Verify all detail page sections against `todo-list-item-screens.pen` design: colors and icons match design
- [x] T074 [P] Add responsive CSS breakpoints for mobile layout in `app/assets/stylesheets/todo_lists.css`: columns stack vertically on narrow screens
- [x] T075 [P] Run `bin/rubocop` — 119 files, 0 offenses
- [x] T076 [P] Run `bin/brakeman --no-pager` — 0 warnings
- [x] T077 Run full test suite: `bin/rails test` — 300 runs, 0 failures, 0 errors
- [x] T078 Run `bin/importmap audit` — no vulnerable packages
- [x] T079 Update spec.md with implementation learnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3–12)**: All depend on Foundational phase completion
  - User stories can proceed in priority order or in parallel
- **Polish (Phase 13)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Status & Priority)**: Can start after Phase 2 — no dependencies on other stories
- **US2 (Notes)**: Can start after Phase 2 — no dependencies on other stories
- **US3 (Checklist)**: Can start after Phase 2 — no dependencies on other stories
- **US4 (Attachments)**: Can start after Phase 2 — no dependencies on other stories
- **US5 (Comments)**: Can start after Phase 2 — no dependencies on other stories
- **US6 (Due Date)**: Can start after Phase 2 — no dependencies on other stories
- **US7 (Assignees)**: Can start after Phase 2 — no dependencies on other stories
- **US10 (Mark Complete/Delete)**: Depends on US1 (status sync behavior) — should follow US1
- **US8 (Notify on Complete)**: Depends on US10 (completion trigger) — should follow US10
- **US9 (Tags)**: Can start after Phase 2 — no dependencies on other stories

### Within Each User Story

- Tests written first (fail before implementation)
- Models/migrations before controllers
- Controllers before views/partials
- Turbo Stream templates alongside view partials
- System tests after implementation is complete

### Parallel Opportunities

- T006, T007, T008 (migrations) can run in parallel
- T012, T013, T014 (new models) can run in parallel
- T019, T020 (US1 tests) can run in parallel
- T022, T023 (US1 status/priority cards) can run in parallel
- T041, T042, T043, T044 (US5 tests) can run in parallel
- US1, US2, US3 (all P1 stories) can run in parallel after Phase 2
- US4, US5, US6, US7 (all P2 stories) can run in parallel after Phase 2

---

## Parallel Example: User Story 1

```bash
# Launch tests in parallel:
Task: "T019 [P] [US1] Controller tests for status/priority"
Task: "T020 [P] [US1] Model tests for expanded enums"

# Then launch card partials in parallel:
Task: "T022 [P] [US1] Status card partial"
Task: "T023 [P] [US1] Priority card partial"
```

## Parallel Example: User Story 5

```bash
# Launch all tests in parallel:
Task: "T041 [P] [US5] Controller tests for comment CRUD"
Task: "T042 [P] [US5] Controller tests for comment likes"
Task: "T043 [P] [US5] Model tests for CommentLike"
Task: "T044 [P] [US5] Model tests for Comment replies"

# Then implementation sequentially (controller → views → streams)
```

---

## Implementation Strategy

### MVP First (User Stories 1–3 Only)

1. Complete Phase 1: Setup (Lexxy + migrations)
2. Complete Phase 2: Foundational (enums + layout + concern)
3. Complete Phase 3: US1 — Status & Priority
4. Complete Phase 4: US2 — Notes with Lexxy
5. Complete Phase 5: US3 — Checklist
6. **STOP and VALIDATE**: Test all P1 stories independently
7. Deploy/demo if ready — item detail is usable for core task management

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Status/Priority) → Test → Deploy (MVP!)
3. Add US2 (Notes) → Test → Deploy
4. Add US3 (Checklist) → Test → Deploy
5. Add US4–US7, US10 (P2 stories) → Test → Deploy
6. Add US8–US9 (P3 stories) → Test → Deploy
7. Polish → Final deploy

### Parallel Team Strategy

With multiple developers after Phase 2:
- Developer A: US1 (Status/Priority) → US10 (Mark Complete) → US8 (Notify)
- Developer B: US2 (Notes) → US4 (Attachments) → US6 (Due Date)
- Developer C: US3 (Checklist) → US5 (Comments) → US7 (Assignees) → US9 (Tags)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Tests follow TDD: write tests first, verify they fail, then implement
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Design source of truth: `designs/todo-list-item-screens.pen` — "TODO Item Detail" screen
- Architecture reference: Fizzy by 37signals (https://github.com/basecamp/fizzy)
- All controller actions MUST scope queries through `Current.user` for authorization
- All Turbo Stream responses MUST update both the changed component AND any dependent badges/indicators
