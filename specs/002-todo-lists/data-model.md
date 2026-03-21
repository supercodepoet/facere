# Data Model: TODO List Management

**Feature Branch**: `002-todo-lists`
**Date**: 2026-03-21

## Entity Relationship Diagram

```
User (existing)
 └── has_many :todo_lists (dependent: :destroy)

TodoList
 ├── belongs_to :user
 ├── has_many :todo_sections (dependent: :destroy)
 └── has_many :todo_items (dependent: :destroy)

TodoSection
 ├── belongs_to :todo_list
 └── has_many :todo_items (dependent: :destroy)

TodoItem
 ├── belongs_to :todo_list
 └── belongs_to :todo_section (optional: true)
```

## Entities

### TodoList

| Field       | Type     | Constraints                                      |
|-------------|----------|--------------------------------------------------|
| id          | integer  | Primary key, auto-increment                      |
| user_id     | integer  | Foreign key → users, NOT NULL                    |
| name        | string   | NOT NULL, max 100 chars, unique per user (case-insensitive) |
| color       | string   | NOT NULL, default: "purple"                      |
| icon        | string   | Nullable, Font Awesome icon name                 |
| description | text     | Nullable, max 500 chars                          |
| template    | string   | NOT NULL, one of: blank, project, weekly, shopping |
| created_at  | datetime | Auto-managed by Rails                            |
| updated_at  | datetime | Auto-managed by Rails                            |

**Indexes**:
- `index_todo_lists_on_user_id`
- `index_todo_lists_on_user_id_and_name` (unique, for case-insensitive uniqueness)

**Validations**:
- `name`: presence, length (max 100), uniqueness (scope: user_id, case_sensitive: false)
- `color`: presence, inclusion in allowed colors
- `description`: length (max 500)
- `template`: presence, inclusion in `%w[blank project weekly shopping]`

**Scopes**:
- `recently_updated`: `order(updated_at: :desc)`

### TodoSection

| Field        | Type     | Constraints                         |
|--------------|----------|-------------------------------------|
| id           | integer  | Primary key, auto-increment         |
| todo_list_id | integer  | Foreign key → todo_lists, NOT NULL  |
| name         | string   | NOT NULL, max 100 chars             |
| position     | integer  | NOT NULL, default: 0                |
| created_at   | datetime | Auto-managed by Rails               |
| updated_at   | datetime | Auto-managed by Rails               |

**Indexes**:
- `index_todo_sections_on_todo_list_id`

**Validations**:
- `name`: presence, length (max 100)
- `position`: presence, numericality (integer, >= 0)

### TodoItem

| Field           | Type     | Constraints                            |
|-----------------|----------|----------------------------------------|
| id              | integer  | Primary key, auto-increment            |
| todo_list_id    | integer  | Foreign key → todo_lists, NOT NULL     |
| todo_section_id | integer  | Foreign key → todo_sections, nullable  |
| name            | string   | NOT NULL, max 255 chars                |
| completed       | boolean  | NOT NULL, default: false               |
| position        | integer  | NOT NULL, default: 0                   |
| created_at      | datetime | Auto-managed by Rails                  |
| updated_at      | datetime | Auto-managed by Rails                  |

**Indexes**:
- `index_todo_items_on_todo_list_id`
- `index_todo_items_on_todo_section_id`

**Validations**:
- `name`: presence, length (max 255)
- `position`: presence, numericality (integer, >= 0)

### User (existing — additions only)

| Addition                         | Details                          |
|----------------------------------|----------------------------------|
| `has_many :todo_lists`           | dependent: :destroy              |

## Template Definitions

Templates are defined as a constant `TEMPLATES` on the `TodoList` model:

```ruby
TEMPLATES = {
  "blank" => { sections: [], items: [] },
  "project" => {
    sections: ["Planning", "In Progress", "Review", "Done"],
    items: {
      "Planning" => ["Define project scope", "Set budget limits", "Research materials needed"],
      "In Progress" => [],
      "Review" => [],
      "Done" => []
    }
  },
  "weekly" => {
    sections: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    items: {}
  },
  "shopping" => {
    sections: ["Produce", "Dairy & Eggs", "Meat & Seafood", "Pantry", "Frozen", "Household"],
    items: {
      "Produce" => ["Fruits", "Vegetables"],
      "Dairy & Eggs" => ["Milk", "Eggs", "Cheese"],
      "Meat & Seafood" => [],
      "Pantry" => [],
      "Frozen" => [],
      "Household" => []
    }
  }
}.freeze
```

## Color Palette

Defined as a constant `COLORS` on the `TodoList` model, matching the design reference:

```ruby
COLORS = %w[purple blue teal green pink orange].freeze
```

CSS custom properties map these to hex values for rendering:
- `--list-color-purple: #8B5CF6`
- `--list-color-blue: #3B82F6`
- `--list-color-teal: #14B8A6`
- `--list-color-green: #22C55E`
- `--list-color-pink: #EC4899`
- `--list-color-orange: #F97316`

## Icon Options

Curated set stored as a constant `ICONS` on the `TodoList` model:

```ruby
ICONS = %w[
  list-check cart-shopping briefcase book
  dumbbell house utensils plane
  graduation-cap heart-pulse music palette
].freeze
```

## Cascade Behavior

- Deleting a `User` → destroys all their `TodoList` records
- Deleting a `TodoList` → destroys all its `TodoSection` and `TodoItem` records
- Deleting a `TodoSection` → destroys all its `TodoItem` records
