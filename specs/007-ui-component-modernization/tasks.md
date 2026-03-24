# Tasks: UI Component Modernization

**Input**: Design documents from `/specs/007-ui-component-modernization/`
**Prerequisites**: plan.md, spec.md

## Completed Tasks

### Phase 1: Web Awesome Icon Removal
- [x] T001 Replace all `wa-icon` elements in `app/views/todo_items/` with `<i class="fa-thin fa-{name}"></i>` (13 files)
- [x] T002 Replace all `wa-icon` elements in remaining views (layouts, todo_lists, shared, auth — 30 files)
- [x] T003 Add Web Awesome kit script to `app/views/layouts/app.html.erb` (was missing, causing icons not to render)

### Phase 2: Web Awesome Button Removal
- [x] T004 Replace all `wa-button` elements with `<button>` or `<a>` (19 files)
- [x] T005 Remove Web Awesome attributes: variant, size, appearance, outline, slot

### Phase 3: Web Awesome Dropdown Removal
- [x] T006 Create `app/javascript/controllers/dropdown_controller.js` (toggle, close on outside click, select dispatch)
- [x] T007 Add dropdown CSS to `todo_lists.css` (`.dropdown-wrap`, `.dropdown-menu`, `.dropdown-item`, `.dropdown-divider`)
- [x] T008 Rewrite `_item_context_menu.html.erb` to use custom dropdown
- [x] T009 Rewrite `_section_context_menu.html.erb` to use custom dropdown
- [x] T010 Rewrite `_inline_section_input.html.erb` icon picker to use custom dropdown
- [x] T011 Update `context_menu_controller.js` — replace inline `wa-*` HTML, update icon swapping and dropdown close logic
- [x] T012 Update `inline_section_controller.js` — update icon class swapping and dropdown close logic

### Phase 4: Web Awesome Dialog Removal
- [x] T013 Create `app/javascript/controllers/modal_controller.js` (close, backdropClose, stopPropagation)
- [x] T014 Add modal CSS (`.delete-modal-overlay`, `.delete-modal-panel`, `.delete-modal--open`)
- [x] T015 Rewrite `_delete_confirmation.html.erb` from `wa-dialog` to custom modal

### Phase 5: Icon Weight Change
- [x] T016 Replace all `fa-thin` with `fa-light` across 41 files (120 occurrences)

### Phase 6: Notes Lexxy Editor
- [x] T017 Add view/edit toggle to `_notes_section.html.erb` — content card with Edit button, hidden Lexxy editor
- [x] T018 Add Cancel button to notes editor, right-align Cancel + Save
- [x] T019 Style Lexxy toolbar in `todo_lists.css` to match visual reference (#F4F4F5 bg, 8px gap, 8px 14px padding)
- [x] T020 Style editor content area (16px 20px padding, 150px min-height, 14px font)
- [x] T021 Style bottom action bar (#F4F4F5 bg, 8px 14px padding, border-top)
- [x] T022 Match editor text size (14px/1.6 line-height) to view mode

### Phase 7: Comments Lexxy Editor
- [x] T023 Add `has_rich_text :rich_body` to Comment model
- [x] T024 Update CommentsController to permit `:rich_body`
- [x] T025 Make `body` validation conditional (`unless: :rich_body?`)
- [x] T026 Rewrite `_comments_section.html.erb` with avatar + Lexxy editor layout
- [x] T027 Update `_comment.html.erb` to display `rich_body` with `body` fallback
- [x] T028 Style comment editor to match Notes editor (toolbar, content, bottom bar)
- [x] T029 Right-align Post button, purple (#8B5CF6) styling
- [x] T030 Remove outer border from comment input row, keep on editor wrap

### Phase 8: Item Detail Layout
- [x] T031 Move Mark Complete + Delete buttons from sidebar to top bar in `show.html.erb`
- [x] T032 Style top bar buttons (teal complete, red bordered delete) matching visual reference
- [x] T033 Add delete confirmation modal for item detail
- [x] T034 Fix assignee row spacing (8px margin between entries)
- [x] T035 Darken/thicken section dividers (1px #F4F4F5 → 2px #E4E4E7)
- [x] T036 Make context menu dots thicker (fa-solid) and darker (#52525B)
- [x] T037 Remove border from item context menu dots button
- [x] T038 Raise dropdown z-index to 9999
- [x] T039 Make delete button same size as other header buttons (remove padding override)

### Phase 9: Inline Item Fix
- [x] T040 Move `data-controller="inline-item"` from form to wrapper div (fix Stimulus target scope)
- [x] T041 Update `requestSubmit()` to target child form
- [x] T042 Hide empty hint when `.todo-item` elements exist anywhere on page
- [x] T043 Hide divider above hint when hint is hidden
- [x] T044 Add 12px top margin to `.inline-item-wrapper`

### Phase 10: Documentation
- [x] T045 Update all spec/plan/task files to remove Web Awesome references (35 files)
- [x] T046 Update constitution to remove Web Awesome rules
- [x] T047 Update CLAUDE.md to remove Web Awesome from tech stack
- [x] T048 Create 007 spec.md, plan.md, tasks.md documenting all changes

## Deferred Tasks (Future Work)

- [ ] T-FUTURE-001 Replace `wa-input` in auth forms (sessions, registrations, passwords, 2FA, oauth) with standard `<input>` elements
- [ ] T-FUTURE-002 Replace `wa-input` in `_form.html.erb` (todo list name) and `_sidebar.html.erb` (search) with standard `<input>`
- [ ] T-FUTURE-003 Replace `wa-checkbox` in `registrations/new.html.erb` and `terms_acceptance.html.erb` with `<input type="checkbox">`
- [ ] T-FUTURE-004 Replace `wa-callout` in `registrations/new.html.erb` and `recovery_codes.html.erb` with styled `<div>` alerts
- [ ] T-FUTURE-005 Remove Web Awesome kit script from `application.html.erb` and `authentication.html.erb` once all `wa-*` replaced
- [ ] T-FUTURE-006 Migrate Comment model: remove `body` column once all comments use `rich_body`
- [ ] T-FUTURE-007 Remove orphaned `_actions_card.html.erb` partial (buttons moved to top bar)
- [ ] T-FUTURE-008 Implement "New list from group" section context menu action (deferred from 006)
