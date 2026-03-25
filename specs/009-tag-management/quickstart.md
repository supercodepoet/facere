# Quickstart: Tag Management

**Feature**: 009-tag-management
**Date**: 2026-03-24

## Prerequisites

- Ruby 4.0.1 / Rails 8.1.2 (existing)
- SQLite (existing)
- All existing gems (no new dependencies)

## Setup

No additional setup needed — this feature builds entirely on existing infrastructure.

```bash
bin/dev  # Start development server
```

## What Changes

### Routes
- Expand `resources :tags` from `only: [:create, :destroy]` to include `[:index, :create, :update, :destroy]`
- `index`: renders tag editor dropdown (Turbo Frame)
- `create`: creates tag + applies to item (enhanced with Turbo Stream response)
- `update`: edits tag name/color
- `destroy`: enhanced to handle both "remove from item" and "delete tag entirely"

### Controller (TagsController)
- Add `index` action — renders tag editor dropdown partial
- Add `update` action — updates tag name/color
- Enhance `destroy` — distinguish "remove from item" vs "delete tag permanently" via param
- All actions respond with Turbo Stream/Frame for inline updates

### Views
- Replace `_tags_card.html.erb` — new design with tag editor dropdown trigger
- Add `_tag_editor.html.erb` — dropdown with search, tag list, checkmarks
- Add `_tag_form.html.erb` — create/edit tag form with color picker
- Add `_tag_delete_confirm.html.erb` — delete confirmation dialog

### JavaScript
- Add `tag_editor_controller.js` — manages editor state (search filtering, view transitions between list/create/edit)
- Reuse existing `dropdown_controller.js` for ellipsis menus
- Reuse existing `modal_controller.js` for delete confirmation

### CSS
- Tag editor dropdown styles
- Color picker preset swatches
- Tag row hover states with ellipsis reveal

## Testing

```bash
bin/rails test test/controllers/tags_controller_test.rb  # Controller tests
bin/rails test test/models/tag_test.rb                    # Model tests
bin/rails test:system                                      # System tests
```

## Design Reference

Open `designs/todo-list-item-screens.pen` in Pencil editor. Reference screens:
- Tag Editor Open, Tag Editor - Ellipsis Menu, Create New Tag, Edit Tag, Delete Tag Confirm
