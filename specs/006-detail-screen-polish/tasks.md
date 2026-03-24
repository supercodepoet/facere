# Tasks: Detail Screen Polish

**Input**: Design documents from `/specs/006-detail-screen-polish/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Not explicitly requested. Test tasks omitted.

**Organization**: Tasks grouped by user story. 7 user stories across 5 phases. View-layer only — no models or migrations.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1–US7) this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Visual audit — screenshot current state and compare against .pen design to identify all gaps

- [x] T001 Screenshot current TODO List Detail and TODO Item Detail screens via the running app and compare against .pen design nodes `nGCDe` and `sogSu` to create a gap list
- [x] T002 Read all partials that will be modified to understand current implementation state: app/views/todo_lists/_todo_item.html.erb, _todo_item_completed.html.erb, _section_context_menu.html.erb, _item_context_menu.html.erb, and app/views/todo_items/_notes_section.html.erb, _assignees_card.html.erb, _due_date_card.html.erb, _notify_card.html.erb, _attachments_section.html.erb

---

## Phase 2: User Story 1 — Item Pills and Badges on List View (Priority: P1) 🎯 MVP

**Goal**: Each item row displays due date badge, priority dot, and assignee avatars matching the .pen design.

**Independent Test**: Open a list with items that have due dates, priorities, and assignees. Verify badges, dots, and avatars display inline.

### Implementation for User Story 1

- [x] T003 [P] [US1] Update app/views/todo_lists/_todo_item.html.erb to ensure due date badge displays with urgency-based coloring (green distant, yellow ≤3 days, red overdue) matching the .pen design — verify the existing `due-badge` class and `due_date_style` method produce the correct colors
- [x] T004 [P] [US1] Update app/views/todo_lists/_todo_item.html.erb to ensure priority dot displays with correct colors (none=hidden, low=teal, medium=blue, high=amber, urgent=red) — verify `priority-dot--{level}` classes exist in CSS with correct colors
- [x] T005 [P] [US1] Update app/views/todo_lists/_todo_item.html.erb to ensure assignee avatar(s) display correctly — show up to 2 avatars with +N overflow count, matching the .pen design avatar stack styling
- [x] T006 [US1] Update app/views/todo_lists/_todo_item.html.erb to add status indicator on the checkbox circle (colored ring or fill matching item status: purple for in_progress, amber for on_hold, teal for done) per the .pen design
- [x] T007 [US1] Update app/views/todo_lists/_todo_item_completed.html.erb to include the same due date badge, priority dot, and assignee avatars as the active item partial (with completed/strikethrough styling)
- [x] T008 [US1] Update app/assets/stylesheets/todo_lists.css to ensure all badge, dot, and avatar styles match the .pen design exactly — verify colors, sizes, spacing, and alignment
- [x] T009 [US1] Take screenshot of list view and compare against .pen node `nGCDe` to validate visual match

**Checkpoint**: List view item rows match the design with all pills, badges, and avatars visible.

---

## Phase 3: User Story 2 — Section and Item Context Menus (Priority: P1)

**Goal**: Context menus on sections and items show all design-specified options and execute actions correctly.

**Independent Test**: Click "..." on a section and on an item, verify all menu options appear and work.

### Implementation for User Story 2

- [x] T010 [P] [US2] Read and update app/views/todo_lists/_section_context_menu.html.erb to include all options from design: Edit, Move..., Copy..., New list from group, Archive group, Delete group, Insert a to-do — using standard dropdown markup per constitution rules
- [x] T011 [P] [US2] Read and update app/views/todo_lists/_item_context_menu.html.erb to include all options from design: Edit, Move..., Copy..., Archive, Delete — using standard dropdown markup, with danger styling for Delete per constitution rules
- [x] T012 [US2] Ensure destructive context menu actions (Delete group, Delete item) show a confirmation dialog before executing (use turbo_confirm or a confirmation dialog)
- [x] T013 [US2] Ensure "Archive group" on section context menu archives the section and all its items (existing controller action — verify wiring)
- [x] T014 [US2] Verify all context menu actions are properly connected to existing controller routes (edit, move, copy, archive, delete for items; same for sections)
- [x] T014a [US2] Implement Move/Copy destination picker for items — when "Move..." or "Copy..." is clicked, show an inline dropdown or modal listing the sections in the current list (plus "No section") as destination options. On selection, submit to the existing move/copy controller actions with target_section_id and target_position params
- [x] T014b [US2] Implement Move/Copy destination picker for sections — when "Move..." or "Copy..." is clicked on a section, show a position selector for reordering within the list. Use existing reorder_sections controller action
- [x] T014c [US2] Mark "New list from group" as deferred — render the menu item as disabled with a tooltip "Coming soon". This action requires a new controller endpoint to create a TodoList from a section's items, which is out of scope for this polish feature

**Checkpoint**: All context menu options match the design and execute correctly (except "New list from group" which is deferred).

---

## Phase 4: User Story 3 — Notes Editor Save Button (Priority: P1)

**Goal**: Notes show "Save" button (not "Done") when editing, button matches design styling, content persists on save.

**Independent Test**: Open item, edit notes, click Save, verify content persists and display updates.

### Implementation for User Story 3

- [x] T015 [US3] Read app/views/todo_items/_notes_section.html.erb and identify the current edit/done button — change label from "Done" to "Save" and update button styling to match design (purple branded button)
- [x] T016 [US3] Read app/javascript/controllers/notes_autosave_controller.js (or equivalent Stimulus controller) and verify the save action persists content via form submission or fetch, updates the display, and exits edit mode
- [x] T017 [US3] Update the notes toolbar button styling in app/assets/stylesheets/ to match the .pen design reference — verify toolbar shows: bold, italic, underline, heading, ordered list, unordered list, link, code, quote icons with correct sizes, spacing, and toolbar background color
- [x] T018 [US3] Verify the notes display updates immediately after save — the rendered rich text content should replace the editor view without a full page reload

**Checkpoint**: Notes Save button works correctly with design-matching styling.

---

## Phase 5: User Stories 4–7 — Item Detail Sidebar Polish (Priority: P2)

**Goal**: Assignee picker, due date calendar, notify picker, and attachment cards all work correctly and match design.

**Independent Test**: Open an item on a shared list, test each sidebar card (assign, date, notify, attachments) independently.

### User Story 4 — Assignee Picker

- [x] T019 [P] [US4] Read and update app/views/todo_items/_assignees_card.html.erb to ensure the picker shows all list members (owner + collaborators) via `todo_list.all_members`, with user avatars and names, and add/remove buttons — matching the .pen design
- [x] T020 [US4] Verify the add/remove actions POST/DELETE to item_assignees routes and the card updates correctly (redirect or turbo_stream response)

### User Story 5 — Due Date Calendar

- [x] T021 [P] [US5] Read and update app/views/todo_items/_due_date_card.html.erb to ensure the date picker works — use native `<input type="date">` for calendar overlay, pre-populate with existing due date, and include a clear date option
- [x] T022 [US5] Verify the date selection saves via PATCH to the todo_item update action and the card display updates with the formatted date (e.g., "March 10, 2026")
- [x] T023 [US5] Read app/javascript/controllers/date_picker_controller.js (if exists) and verify it handles date selection, form submission, and display update

### User Story 6 — Notify on Complete Picker

- [x] T024 [P] [US6] Read and update app/views/todo_items/_notify_card.html.erb to ensure the picker shows all list members (owner + collaborators), with add/remove buttons — same pattern as assignees card
- [x] T025 [US6] Verify the add/remove actions POST/DELETE to notify_people routes and the card updates correctly

### User Story 7 — File Attachments

- [x] T026 [P] [US7] Read and update app/views/todo_items/_attachments_section.html.erb to display each attachment as a card with: filename, file type icon (using TodoItem#file_type_icon), file size (formatted bytes), and colored icon background (using TodoItem#file_type_color) — matching the .pen design horizontal card layout
- [x] T027 [US7] Ensure the Upload button triggers a file selection dialog and the uploaded file appears as a card after completion
- [x] T028 [US7] Ensure each attachment card has a download link (clicking the card downloads/opens the file) and a delete action
- [x] T029 [US7] Update attachment card CSS in app/assets/stylesheets/todo_lists.css to match the .pen design (card background, icon styling, horizontal layout, file size text)

**Checkpoint**: All sidebar cards work correctly and match the design.

---

## Phase 6: Polish & Cross-Cutting

**Purpose**: Final visual validation and CI green

- [x] T030 Take screenshot of TODO List Detail and compare against .pen node `nGCDe` — verify all elements match
- [x] T031 Take screenshot of TODO Item Detail and compare against .pen node `sogSu` — verify all elements match
- [x] T032 Run bin/rubocop on all modified files and fix any offenses
- [x] T033 Run bin/brakeman --no-pager and resolve any warnings
- [x] T034 Run bin/rails test and fix any failures
- [x] T035 Run bin/rails test:system and fix any failures

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — visual audit first
- **Phase 2 (US1 — Pills)**: After Phase 1
- **Phase 3 (US2 — Context Menus)**: After Phase 1, can parallel with Phase 2
- **Phase 4 (US3 — Notes Save)**: After Phase 1, can parallel with Phase 2/3
- **Phase 5 (US4–7 — Sidebar)**: After Phase 1, can parallel with Phase 2/3/4
- **Phase 6 (Polish)**: After all story phases

### Parallel Opportunities

- T003, T004, T005 (list item partials — different concerns) can run in parallel
- T010, T011 (section vs item context menus — different files) can run in parallel
- T019, T021, T024, T026 (different sidebar cards — different files) can run in parallel
- Phases 2, 3, 4, 5 can all start in parallel after Phase 1

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Visual audit
2. Phase 2: Item pills and badges
3. **STOP**: List view matches design — deploy/demo

### Incremental Delivery

1. Visual audit → understand all gaps
2. US1: Item pills → list view matches design
3. US2: Context menus → full list interaction
4. US3: Notes Save → item editing works correctly
5. US4–7: Sidebar cards → full item detail polish
6. Polish → CI green, visual validation

---

## Notes

- This is a **view-layer only** feature — no models, migrations, or new routes
- All partials already exist — modifications only
- Always compare against the .pen design screenshots after changes
- Use standard dropdown markup for all menus per constitution
- Use plain `<input>` elements for form fields per constitution lesson from feature 005
- File type icons and colors already exist as model methods: `TodoItem#file_type_icon`, `TodoItem#file_type_color`
