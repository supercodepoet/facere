# Plan: UI Component Modernization

**Created**: 2026-03-24
**Status**: Implemented
**Feature ID**: 007-ui-component-modernization

## Summary

Remove Web Awesome Pro dependency for icons, buttons, dropdowns, and dialogs. Replace with standard HTML elements + Font Awesome Pro icons. Add Lexxy rich text editing to Notes and Comments. Reorganize Item Detail layout per visual reference.

## Technical Context

- Ruby 4.0.1 / Rails 8.1.2 + Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, Stimulus)
- Font Awesome Pro (CDN kit) — loaded via Web Awesome kit script
- Lexxy (~> 0.9.0.beta) for rich text editing (replaces Trix via ActionText)
- SQLite (all environments)

## Dependencies

- Font Awesome Pro (CDN kit)
- Lexxy gem (already installed)
- ActionText (already configured)

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | PASS | Standard HTML elements, Stimulus controllers |
| II. Library-First | PASS | Font Awesome for icons, Lexxy for rich text |
| III. Joyful UX | PASS | Matches .pen visual reference |
| IV. Clean Architecture | PASS | Stimulus for DOM, server for logic |
| V. Code Quality | PASS | Under 200 lines per file |
| VI. Separation of Concerns | PASS | CSS in stylesheets, JS in controllers |
| VII. Simplicity | PASS | Minimal new abstractions (2 small controllers) |

## Key Technical Decisions

### D1: Standard HTML over Web Awesome custom elements
**Decision**: Replace all `wa-*` elements with standard `<i>`, `<button>`, `<div>` elements
**Rationale**: Web Awesome custom elements caused styling conflicts (toolkit not loaded in all layouts), added a framework dependency for simple UI primitives, and made the markup non-portable. Standard HTML with Font Awesome classes is universally supported.

### D2: Custom dropdown Stimulus controller over library
**Decision**: Build a minimal 35-line `dropdown_controller.js` instead of adding a dropdown library
**Rationale**: The dropdown behavior needed is simple (toggle, close on outside click, dispatch select event). A library would be overkill per Principle VII.

### D3: Custom modal Stimulus controller over dialog element
**Decision**: Build a minimal `modal_controller.js` using overlay + panel divs instead of `<dialog>` or a modal library
**Rationale**: Consistent styling with existing design system. The `<dialog>` element has browser-specific styling that would need overriding. The modal controller is 17 lines.

### D4: Dual-field approach for Comment rich text
**Decision**: Add `has_rich_text :rich_body` alongside existing `body` column rather than migrating
**Rationale**: Preserves existing plain-text comments without a data migration. New comments use `rich_body`, old ones fall back to `body`. Future cleanup task documented.

### D5: fa-light over fa-thin for icon weight
**Decision**: Changed all icons from `fa-thin` (100 weight) to `fa-light` (300 weight)
**Rationale**: `fa-thin` was too light/hairline for readability. `fa-light` provides better visual weight while maintaining the light aesthetic.

## Architecture Learnings

### Stimulus Controller Scope
The `data-controller` attribute defines the scope boundary for `data-{controller}-target` attributes. Targets MUST be descendants of the controller element. When a form (`data-controller="x"`) has sibling elements with targets (`data-x-target="y"`), those targets will never be found. Solution: move the controller to a common ancestor.

### Web Awesome Kit Loading
The Web Awesome kit script was included in `application.html.erb` and `authentication.html.erb` but NOT in `app.html.erb` (the main app layout). This caused all `wa-icon` elements to render as empty/unstyled in the main app. This inconsistency is a key reason the removal was needed.

### Dropdown Event Pattern
The custom dropdown dispatches `dropdown:select` with `{ detail: { item: { value } } }` — this matches the shape of Web Awesome's `wa-select` event, allowing the `context_menu_controller.js` dispatch method to work unchanged.

## Files Modified

### New Files
- `app/javascript/controllers/dropdown_controller.js`
- `app/javascript/controllers/modal_controller.js`

### Modified Files (key changes)
- All 32+ view files in `app/views/` — icon replacements
- All 19 view files with `wa-button` — button replacements
- `app/views/todo_lists/_item_context_menu.html.erb` — dropdown rewrite
- `app/views/todo_lists/_section_context_menu.html.erb` — dropdown rewrite
- `app/views/todo_lists/_inline_section_input.html.erb` — icon picker dropdown rewrite
- `app/javascript/controllers/context_menu_controller.js` — updated inline HTML + icon swapping
- `app/javascript/controllers/inline_section_controller.js` — updated icon swapping + dropdown close
- `app/javascript/controllers/inline_item_controller.js` — controller scope fix + hint logic
- `app/views/todo_items/_notes_section.html.erb` — full Lexxy editor integration
- `app/views/todo_items/_comments_section.html.erb` — Lexxy rich text editor
- `app/views/todo_items/_comment.html.erb` — rich_body display with fallback
- `app/views/todo_items/show.html.erb` — top bar buttons, delete modal
- `app/views/todo_lists/_delete_confirmation.html.erb` — wa-dialog → custom modal
- `app/models/comment.rb` — has_rich_text :rich_body
- `app/controllers/comments_controller.rb` — permit :rich_body
- `app/assets/stylesheets/todo_lists.css` — dropdown, modal, button, editor CSS
- `app/assets/stylesheets/lexxy.css` — notes editor toolbar comments (user-managed)
