# Spec: UI Component Modernization

**Created**: 2026-03-24
**Status**: Implemented
**Feature ID**: 007-ui-component-modernization

## Summary

Replace Web Awesome custom elements (`wa-icon`, `wa-button`, `wa-dropdown`, `wa-dialog`) with standard HTML elements and Font Awesome Pro icons across the entire application. Add Lexxy rich text editors to Notes and Comments sections on the Item Detail screen. Modernize the Item Detail layout to match the visual reference.

## Visual Reference

Source of truth: `designs/todo-list-item-screens.pen`
- Frame `sogSu`: TODO Item Detail (full screen)
- Frame `w6ztN`: Notes Section (editor with toolbar)
- Frame `aeVyp`: Comments Section (comment list + rich editor)

## Changes Implemented

### 1. Web Awesome Component Removal

Removed all `wa-*` custom elements from the app:

- **`wa-icon`** → `<i class="fa-light fa-{name}"></i>` (32+ view files)
- **`wa-button`** → `<button>` or `<a>` for href variants (19 files)
- **`wa-dropdown`** → Custom dropdown with `dropdown` Stimulus controller (3 templates + 2 JS controllers)
- **`wa-dialog`** → Custom modal with `modal` Stimulus controller (delete confirmation)
- **`wa-divider`** → `<hr class="dropdown-divider">`
- Icon weight changed from `fa-thin` to `fa-light` across all 41 files (120 occurrences)

Remaining `wa-*` components NOT yet replaced (future work):
- `wa-input` (auth forms, sidebar search, todo list form)
- `wa-checkbox` (registration, terms acceptance)
- `wa-callout` (registration errors, recovery codes warning)
- `wa-dialog` still used by some list-level confirmations outside todo_items

### 2. Notes Section — Lexxy Editor

- Added view/edit toggle: content displayed in `notes-content-card`, Edit button reveals Lexxy editor
- Lexxy toolbar styled to match visual reference: `#F4F4F5` background, `8px 14px` padding, `8px` gap, `12px` top corners
- Editor content area: `16px 20px` padding, `150px` min-height, `14px` font matching view mode
- Bottom action bar: `#F4F4F5` background, right-aligned Cancel + Save buttons
- Horizontal dividers between toolbar, content, and action bar

### 3. Comments Section — Lexxy Rich Text Editor

- Added `has_rich_text :rich_body` to Comment model (alongside existing plain `body`)
- Comment input changed from single-line text field to Lexxy `rich_text_area`
- Layout: avatar on left, editor card on right (matching visual reference)
- Toolbar and bottom bar styled identically to Notes editor
- Post button: right-aligned, purple (`#8B5CF6`)
- Existing plain-text comments still render via `body` fallback
- `body` validation made conditional: `unless: :rich_body?`

### 4. Item Detail Layout Changes

- **Mark Complete + Delete buttons** moved from right sidebar to top bar (matching visual reference)
- Delete button now triggers a confirmation modal (custom `modal` Stimulus controller) instead of `turbo_confirm`
- Assignee rows: added `8px` vertical spacing between entries
- Section dividers: `1px #F4F4F5` → `2px #E4E4E7` (darker, thicker)
- Context menu dots: changed from `fa-thin` to `fa-solid`, color `#52525B`, removed border on item dots
- Dropdown z-index raised to `9999` to sit on top of all content

### 5. Inline Item Creation — Empty Hint Fix

- "Start typing to add your first item" hint now only shows when the list has zero items
- Root cause: `data-controller` was on the `<form>` but the hint target was a sibling outside the form — Stimulus targets must be descendants of the controller element
- Fix: moved controller to parent `.inline-item-wrapper` div
- Hint + divider hidden after first successful save
- Added `12px` top margin to `.inline-item-wrapper` for spacing

## New Infrastructure Created

### Stimulus Controllers
- `dropdown_controller.js` — Toggle/close/select for custom dropdowns, dispatches `dropdown:select` event
- `modal_controller.js` — Open/close/backdrop-click for custom modals

### CSS Classes
- `.dropdown-wrap`, `.dropdown-menu`, `.dropdown-item`, `.dropdown-divider` — Dropdown styling
- `.delete-modal-overlay`, `.delete-modal-panel`, `.delete-modal--open` — Modal overlay/panel
- `.item-topbar-btn`, `.item-topbar-btn--complete`, `.item-topbar-btn--delete` — Top bar action buttons
- `.comment-input-row`, `.comment-editor-wrap`, `.comment-editor-bottom`, `.comment-post-btn` — Comment editor

## Deferred / Future Work

1. **Replace remaining `wa-input`** across auth forms, sidebar search, and todo list form with standard `<input>` elements
2. **Replace remaining `wa-checkbox`** in registration and terms acceptance with standard `<input type="checkbox">`
3. **Replace remaining `wa-callout`** in registration and recovery codes with styled `<div>` alerts
4. **Migrate Comment `body` to rich text only** — currently dual-field (`body` + `rich_body`); once all comments use `rich_body`, remove the `body` column
5. **"New list from group"** context menu action — currently disabled/deferred from 006
6. **Move/Copy actions** in context menus — UI wired but some backend actions may need completion
7. **Remove Web Awesome kit script** from `application.html.erb` and `authentication.html.erb` once all `wa-*` components are replaced
8. **Remove `_actions_card.html.erb`** partial — buttons moved to top bar, partial may be orphaned
