# Quickstart: TODO Item Detail Screen

**Branch**: `004-todo-item-detail` | **Date**: 2026-03-22

## Prerequisites

- Ruby 4.0.1 / Rails 8.1.2 (already configured)
- Existing feature 003 (todo-list-items) merged to main
- Lexxy gem access (public beta)

## Setup Steps

### 1. Install Lexxy

```bash
# Add to Gemfile
bundle add lexxy --version '~> 0.1.26.beta'

# Pin JavaScript via Importmap
bin/importmap pin lexxy

# Add to app/javascript/application.js
# import "lexxy"
```

### 2. Configure Lexxy

```ruby
# config/initializers/lexxy.rb
Rails.application.config.lexxy.override_action_text_defaults = true
```

### 3. Add Lexxy Stylesheets

Add Lexxy CSS imports to the application stylesheet or layout. Lexxy provides:
- `lexxy.css` — base styles
- `lexxy-editor.css` — editor chrome
- `lexxy-content.css` — rendered content styles
- `lexxy-variables.css` — CSS custom properties for theming

### 4. Run Migrations

```bash
bin/rails generate migration AddOnHoldAndUrgentToTodoItems
bin/rails generate migration AddReplyAndEditSupportToComments parent_id:integer edited_at:datetime likes_count:integer
bin/rails generate migration CreateCommentLikes comment:references user:references
bin/rails generate migration CreateNotifyPeople todo_item:references user:references
bin/rails db:migrate
```

### 5. Run Tests

```bash
bin/rails test                 # Unit + integration
bin/rails test:system          # System tests
bin/rubocop                    # Lint
bin/brakeman --no-pager        # Security scan
```

## Key Files to Create/Modify

### New Models
- `app/models/comment_like.rb`
- `app/models/notify_person.rb`

### New Controllers
- `app/controllers/comment_likes_controller.rb`
- `app/controllers/notify_people_controller.rb`

### Modified Models
- `app/models/todo_item.rb` — expanded enums, notify_people association
- `app/models/comment.rb` — parent/replies, edited_at, likes

### Modified Controllers
- `app/controllers/comments_controller.rb` — add update action
- `app/controllers/todo_items_controller.rb` — enhanced show with eager loading

### New Stimulus Controllers
- `app/javascript/controllers/notes_autosave_controller.js` — Lexxy auto-save
- `app/javascript/controllers/comment_like_controller.js` — like toggle
- `app/javascript/controllers/date_picker_controller.js` — due date quick picks

### Views (Modified/New)
- `app/views/todo_items/show.html.erb` — enhanced detail layout
- `app/views/todo_items/_notes_section.html.erb` — Lexxy always-editable
- `app/views/todo_items/_comments_section.html.erb` — likes, replies, edit/delete
- `app/views/todo_items/_comment.html.erb` — individual comment partial
- `app/views/todo_items/_status_sidebar.html.erb` — expanded statuses
- `app/views/todo_items/_priority_card.html.erb` — new priority card
- `app/views/todo_items/_assignees_card.html.erb` — assignees display
- `app/views/todo_items/_due_date_card.html.erb` — due date with countdown
- `app/views/todo_items/_notify_card.html.erb` — notify on complete
- Various Turbo Stream templates for partial updates

## Design Reference

Source of truth: `designs/todo-list-item-screens.pen` — "TODO Item Detail" screen

### Key Colors (from design)
- Primary/Accent: `#8B5CF6` (purple)
- Text Primary: `#18181B`
- Text Secondary: `#71717A`
- Text Muted: `#A1A1AA`
- Border: `#D4D4D8`
- Surface: `#F4F4F5`
- Success/Complete: `#14B8A6` (teal)
- Destructive: `#EF4444` (red)
- Warning/Urgent: `#F59E0B` (amber)

### Priority Colors
- Urgent: `#EF4444` (red)
- High: `#F59E0B` (amber)
- Normal: `#3B82F6` (blue)
- Low: `#14B8A6` (teal)
- None: `#A1A1AA` (gray)

### Status Colors
- To Do: `#A1A1AA` (gray text)
- In Progress: `#8B5CF6` (purple fill)
- On Hold: `#A1A1AA` (gray text)
- Done: `#A1A1AA` (gray text)

## Architecture Reference

Follow Fizzy (37signals) patterns:
- Thin controllers, rich domain models with concerns
- Scoped concerns for nested controllers (e.g., `TodoItemScoped`)
- Turbo Frames per editable component
- Turbo Streams for partial page updates
- Stimulus controllers for DOM-only interactions
- Auto-save pattern: debounced change events → form submission
