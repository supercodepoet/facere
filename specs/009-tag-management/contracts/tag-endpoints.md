# Tag Endpoints Contract

**Feature**: 009-tag-management
**Date**: 2026-03-24

## Routes

All routes nested under `todo_list > todo_item > tags`.

### GET /todo_lists/:todo_list_id/todo_items/:todo_item_id/tags

**Purpose**: Render tag editor dropdown (Turbo Frame)
**Response**: HTML partial with tag list, search field, checkmarks
**Auth**: Requires authenticated user with list access

### POST /todo_lists/:todo_list_id/todo_items/:todo_item_id/tags

**Purpose**: Dual-purpose — create a new tag OR toggle an existing tag onto the item
**Params**:
- New tag creation: `tag[name]` (required), `tag[color]` (optional hex)
- Toggle existing tag on: `tag[id]` (existing tag ID to apply to item)
**Response**: Turbo Stream updating tag editor and tags display. On successful creation, search field is reset and full tag list is shown
**Auth**: Requires editor permission on list
**Validation errors**: Re-render form with error messages (e.g., duplicate name)

### PATCH /todo_lists/:todo_list_id/todo_items/:todo_item_id/tags/:id

**Purpose**: Update tag name and/or color
**Params**: `tag[name]`, `tag[color]`
**Response**: Turbo Stream updating tag editor and all tag displays
**Auth**: Requires editor permission on list; tag must belong to current user
**Validation errors**: Re-render edit form with error messages

### DELETE /todo_lists/:todo_list_id/todo_items/:todo_item_id/tags/:id

**Purpose**: Either remove tag from item OR permanently delete the tag
**Params**: `permanent=true` (optional) — if present, deletes the tag entirely
**Response**: Turbo Stream removing tag from editor/display
**Auth**: Requires editor permission on list; tag must belong to current user (for permanent delete)

## Turbo Frame IDs

| Frame ID                    | Purpose                              |
|-----------------------------|--------------------------------------|
| `item_tags_{item_id}`       | Wraps entire tags card section        |
| `tag_editor_{item_id}`      | Tag editor dropdown content           |
| `tag_form_{item_id}`        | Create/edit tag form area             |

## Turbo Stream Targets

| Target                      | Action  | When                              |
|-----------------------------|---------|-----------------------------------|
| `item_tags_{item_id}`       | replace | After tag toggle, create, delete  |
| `tag_editor_{item_id}`      | replace | After tag create, edit, delete    |
