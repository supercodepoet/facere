# Quickstart: TODO List Items Management

**Feature**: 003-todo-list-items | **Date**: 2026-03-21

## Prerequisites

- Ruby 4.0.1 / Rails 8.1.2 (already configured)
- SQLite (already configured)
- Web Awesome Pro CDN (already in app layout)
- Font Awesome Pro CDN (already in app layout)
- Feature 002 (TODO Lists) must be complete and merged

## Setup Steps

### 1. Install ActionText

ActionText is needed for rich text notes on TODO items.

```bash
bin/rails action_text:install
```

This will:
- Create `db/migrate/*_create_action_text_tables.rb`
- Create `db/migrate/*_create_active_storage_tables.rb` (if not present)
- Add ActionText JavaScript to importmap
- Create `app/views/active_storage/blobs/_blob.html.erb`
- Create `app/views/layouts/action_text/contents/_content.html.erb`
- Add `app/assets/stylesheets/actiontext.css`

### 2. Run Migrations

```bash
bin/rails db:migrate
```

Migrations in order:
1. ActionText tables (from step 1)
2. `add_fields_to_todo_items` — status, due_date, priority, archived
3. `add_fields_to_todo_sections` — icon, archived
4. `create_checklist_items`
5. `create_tags_and_item_tags`

### 3. Verify Setup

```bash
bin/rails test          # All existing tests should pass
bin/rails test:system   # All existing system tests should pass
bin/dev                 # Start dev server, verify lists still work
```

## Development Commands

```bash
bin/dev                          # Start development server
bin/rails test                   # Run all unit/controller tests
bin/rails test:system            # Run system tests
bin/rails db:migrate             # Run pending migrations
bin/rails db:rollback STEP=N     # Rollback N migrations
bin/rubocop                      # Lint check
bin/brakeman --no-pager          # Security scan
```

## Key File Locations

| What | Where |
|------|-------|
| Item controller | `app/controllers/todo_items_controller.rb` |
| Section controller | `app/controllers/todo_sections_controller.rb` |
| Item model | `app/models/todo_item.rb` |
| Section model | `app/models/todo_section.rb` |
| Checklist model | `app/models/checklist_item.rb` |
| Tag model | `app/models/tag.rb` |
| List show view | `app/views/todo_lists/show.html.erb` |
| Item detail view | `app/views/todo_items/show.html.erb` |
| Stimulus controllers | `app/javascript/controllers/` |
| Styles | `app/assets/stylesheets/todo_lists.css` |
| Routes | `config/routes.rb` |
| Design reference | `designs/todo-list-item-screens.pen` |

## Design Reference

Use the Pencil MCP tools to view design screens:

```
mcp__pencil__get_screenshot(filePath: "designs/todo-list-item-screens.pen", nodeId: "...")
```

| Screen | Node ID |
|--------|---------|
| Adding First Item - Inline | `Md812` |
| Adding Section - Inline | `kxC0I` |
| List With Items & Sections | `QBfz6` |
| TODO List Detail | `nGCDe` |
| TODO Item Detail | `sogSu` |
| Section Context Menu | `Df59j` |
| Item Context Menu | `9xhXA` |
| Drag to Reorder | `mg9id` |

## Testing Approach

- **Model tests**: Validations, scopes, business logic (toggle, archive, due date styling)
- **Controller tests**: CRUD actions, authorization (scoped to user), parameter injection, Turbo Stream responses
- **System tests**: Inline creation (Enter/Esc), drag-and-drop, context menus, item detail interactions
- **Web Awesome helpers**: Use `execute_script` for shadow DOM interactions (wa-input, wa-button, wa-dropdown)
