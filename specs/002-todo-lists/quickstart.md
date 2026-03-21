# Quickstart: TODO List Management

**Feature Branch**: `002-todo-lists`
**Date**: 2026-03-21

## Prerequisites

1. Ruby 4.0.1 installed (check `.ruby-version`)
2. Rails 8.1.2 (`bin/rails --version`)
3. SQLite3 available
4. Branch `002-todo-lists` checked out

## Setup

```bash
# Install dependencies
bundle install

# Run migrations (existing + new)
bin/rails db:migrate

# Verify tests pass
bin/rails test
```

## Key Files to Create

### Database
- `db/migrate/YYYYMMDDHHMMSS_create_todo_lists.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_todo_sections.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_todo_items.rb`

### Models
- `app/models/todo_list.rb` — Core model with validations, scopes, template definitions, color/icon constants
- `app/models/todo_section.rb` — Section model with position ordering
- `app/models/todo_item.rb` — Item model with completion tracking

### Controller
- `app/controllers/todo_lists_controller.rb` — Standard CRUD (index, new, create, show, edit, update, destroy)

### Views
- `app/views/layouts/app.html.erb` — Authenticated app layout (top nav bar)
- `app/views/todo_lists/index.html.erb` — Listing with blank slate
- `app/views/todo_lists/new.html.erb` — Create form
- `app/views/todo_lists/edit.html.erb` — Edit form
- `app/views/todo_lists/show.html.erb` — Detail view with empty state
- `app/views/todo_lists/_form.html.erb` — Shared form partial
- `app/views/todo_lists/_list_card.html.erb` — Card partial for listing grid
- `app/views/todo_lists/_sidebar.html.erb` — Left sidebar navigation
- `app/views/todo_lists/_delete_confirmation.html.erb` — Delete modal

### Stimulus Controllers
- `app/javascript/controllers/color_picker_controller.js`
- `app/javascript/controllers/icon_picker_controller.js`
- `app/javascript/controllers/template_picker_controller.js`
- `app/javascript/controllers/delete_confirmation_controller.js`
- `app/javascript/controllers/list_search_controller.js`

### Stylesheets
- `app/assets/stylesheets/todo_lists.css`

### Tests
- `test/models/todo_list_test.rb`
- `test/models/todo_section_test.rb`
- `test/models/todo_item_test.rb`
- `test/controllers/todo_lists_controller_test.rb`
- `test/system/todo_lists_test.rb`

## Routes Addition

```ruby
# config/routes.rb — add before root
resources :todo_lists, path: "lists"
```

## Key Implementation Notes

1. **Layout**: Create `app.html.erb` layout with top nav bar (Facere logo, search, notification bell, user avatar). Apply to `TodoListsController` via `layout "app"`.

2. **Authentication**: Use existing `Authentication` concern — `before_action :require_authentication` and scope all queries through `Current.user.todo_lists`.

3. **Template seeding**: After creating a TodoList, call `apply_template!` to populate sections and items based on the selected template.

4. **Color rendering**: Use CSS custom properties (`--list-color-{name}`) and a `data-color` attribute on elements to apply the correct color via CSS.

5. **Delete flow**: Use `wa-dialog` for confirmation modal, controlled by `delete-confirmation-controller`. The actual delete is a standard Rails `button_to` with `method: :delete` inside the dialog.

6. **Root route**: Update `root` from `sessions#new` to `todo_lists#index` (authenticated users go to lists, unauthenticated redirect to sign in).

## Verification

```bash
# Run all tests
bin/rails test
bin/rails test:system

# Lint
bin/rubocop

# Security
bin/brakeman --no-pager
```
