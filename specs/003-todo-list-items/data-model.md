# Data Model: TODO List Items Management

**Feature**: 003-todo-list-items | **Date**: 2026-03-21

## Entity Relationship Overview

```
User
 └── TodoList (existing)
      ├── TodoSection (extended)
      │    └── TodoItem (extended)
      │         ├── ChecklistItem (new)
      │         ├── Comment (new)
      │         ├── Tag (via ItemTag join, new)
      │         ├── ActionText::RichText (notes, via ActionText)
      │         └── ActiveStorage::Attachment (files, via Active Storage)
      └── TodoItem (unsectioned, extended)
           └── (same children as above)

User
 ├── Tag (new, user-scoped)
 └── Comment (new, via todo_items)
```

## Extended Entities

### TodoItem (existing table: `todo_items`)

**New columns:**

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| status | string | "todo" | false | One of: todo, in_progress, done |
| due_date | date | nil | true | Optional due date |
| priority | string | "none" | false | One of: none, low, medium, high |
| archived | boolean | false | false | Soft-hide from default view |
| assigned_to_user_id | integer | nil | true | FK to users (single-user stub, assign to self) |

**Existing columns (unchanged):**

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| name | string | — | false | Required, max 255 chars |
| completed | boolean | false | false | Checkbox state |
| position | integer | 0 | false | Ordering within list/section |
| todo_list_id | integer | — | false | FK to todo_lists |
| todo_section_id | integer | — | true | FK to todo_sections (optional) |

**Associations:**
- `belongs_to :todo_list`
- `belongs_to :todo_section, optional: true`
- `has_many :checklist_items, dependent: :destroy`
- `has_many :comments, dependent: :destroy`
- `has_many :item_tags, dependent: :destroy`
- `has_many :tags, through: :item_tags`
- `belongs_to :assigned_to, class_name: "User", optional: true`
- `has_rich_text :notes` (ActionText)
- `has_many_attached :files` (Active Storage)

**Validations:**
- name: presence, length max 255
- position: presence, numericality (integer, >= 0)
- status: presence, inclusion in STATUSES
- priority: presence, inclusion in PRIORITIES
- completed: boolean

**Scopes:**
- `active` → `where(archived: false)`
- `completed` → `where(completed: true)`
- `incomplete` → `where(completed: false)`
- `overdue` → `where("due_date < ?", Date.current).where(completed: false)`
- `by_position` → `order(:position)`

**Constants:**
- `STATUSES = %w[todo in_progress done].freeze`
- `PRIORITIES = %w[none low medium high].freeze`
- `PRIORITY_COLORS = { "none" => nil, "low" => "teal", "medium" => "orange", "high" => "danger" }.freeze`

**Business logic:**
- `completed?` → returns `completed` boolean
- `overdue?` → `due_date.present? && due_date < Date.current && !completed?`
- `due_date_style` → returns CSS class based on due date proximity
- `toggle_completion!` → toggles `completed` and syncs `status` (completed → "done", uncompleted → "todo")
- `archive!` → sets `archived: true`

### TodoSection (existing table: `todo_sections`)

**New columns:**

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| icon | string | nil | true | Font Awesome icon name |
| archived | boolean | false | false | Soft-hide from default view |

**Existing columns (unchanged):**

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| name | string | — | false | Required, max 100 chars |
| position | integer | 0 | false | Ordering within list |
| todo_list_id | integer | — | false | FK to todo_lists |

**Scopes:**
- `active` → `where(archived: false)`
- `by_position` → `order(:position)`

**Business logic:**
- `archive!` → sets `archived: true` on section AND all contained items
- `item_count` → active items count

## New Entities

### ChecklistItem (new table: `checklist_items`)

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| id | integer | auto | false | Primary key |
| name | string | — | false | Required, max 255 chars |
| completed | boolean | false | false | Individual completion state |
| position | integer | 0 | false | Ordering within checklist |
| todo_item_id | integer | — | false | FK to todo_items |
| created_at | datetime | auto | false | |
| updated_at | datetime | auto | false | |

**Associations:**
- `belongs_to :todo_item`

**Validations:**
- name: presence, length max 255
- position: presence, numericality (integer, >= 0)

**Indexes:**
- `todo_item_id`

### Tag (new table: `tags`)

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| id | integer | auto | false | Primary key |
| name | string | — | false | Required, max 50 chars, unique per user |
| color | string | nil | true | Optional CSS color name/value |
| user_id | integer | — | false | FK to users (scoped per user) |
| created_at | datetime | auto | false | |
| updated_at | datetime | auto | false | |

**Associations:**
- `belongs_to :user`
- `has_many :item_tags, dependent: :destroy`
- `has_many :todo_items, through: :item_tags`

**Validations:**
- name: presence, length max 50, uniqueness scoped to user_id (case-insensitive)

**Indexes:**
- `[user_id, name]` (unique, case-insensitive)

### ItemTag (new join table: `item_tags`)

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| id | integer | auto | false | Primary key |
| todo_item_id | integer | — | false | FK to todo_items |
| tag_id | integer | — | false | FK to tags |
| created_at | datetime | auto | false | |
| updated_at | datetime | auto | false | |

**Associations:**
- `belongs_to :todo_item`
- `belongs_to :tag`

**Validations:**
- Unique constraint on `[todo_item_id, tag_id]`

**Indexes:**
- `[todo_item_id, tag_id]` (unique)
- `tag_id`

### Comment (new table: `comments`)

| Field | Type | Default | Null | Notes |
|-------|------|---------|------|-------|
| id | integer | auto | false | Primary key |
| body | text | — | false | Required, max 2000 chars |
| todo_item_id | integer | — | false | FK to todo_items |
| user_id | integer | — | false | FK to users |
| created_at | datetime | auto | false | |
| updated_at | datetime | auto | false | |

**Associations:**
- `belongs_to :todo_item`
- `belongs_to :user`

**Validations:**
- body: presence, length max 2000

**Indexes:**
- `todo_item_id`
- `user_id`

## Migration Summary

1. `add_fields_to_todo_items` — adds status, due_date, priority, archived, assigned_to_user_id columns
2. `add_fields_to_todo_sections` — adds icon, archived columns
3. `create_checklist_items` — new table with todo_item_id FK
4. `create_tags_and_item_tags` — new tags table + item_tags join table
5. `create_comments` — new comments table with todo_item_id and user_id FKs
6. ActionText installation: `bin/rails action_text:install` (creates action_text_rich_texts + active_storage tables if not present)

## State Transitions

### TodoItem Status

```
todo ──→ in_progress ──→ done
  ↑          ↑             │
  │          │             │
  └──────────┴─────────────┘
  (any status can transition to any other)
```

No constraints on transitions — users can move items freely between states.

### TodoItem Completion Sync

When `completed` is toggled:
- `completed: true` → `status` automatically set to `"done"`
- `completed: false` → `status` automatically set to `"todo"`

When `status` is changed directly:
- `status: "done"` → `completed` automatically set to `true`
- `status: "todo"` or `"in_progress"` → `completed` automatically set to `false`
