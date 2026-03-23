# Data Model: TODO Item Detail Screen

**Branch**: `004-todo-item-detail` | **Date**: 2026-03-22

## Entity Changes

### Modified: TodoItem

**New/Changed Fields**:
- `status`: Add `on_hold` to enum values → `todo` (default), `in_progress`, `on_hold`, `done`
- `priority`: Add `urgent`, rename `medium` → `normal` → `none` (default), `low`, `normal`, `high`, `urgent`

**New Associations**:
- `has_many :notify_people, dependent: :destroy`
- `has_many :comment_likes, through: :comments` (for eager loading)

**Updated Callbacks**:
- `sync_completion_and_status`: Updated to handle `on_hold` status. Setting status to `done` → `completed = true`. Setting status to anything else → `completed = false`. Setting `completed = true` → `status = :done`. Unmarking complete → `status = :todo`.

**State Transitions** (status):
```
         ┌──────────┐
    ┌────│  To Do   │────┐
    │    │ (default)│    │
    │    └──────────┘    │
    ▼                    ▼
┌──────────┐      ┌──────────┐
│In Progress│◄────►│ On Hold  │
└──────────┘      └──────────┘
    │                    │
    ▼                    ▼
         ┌──────────┐
         │   Done   │ ←→ completed = true
         └──────────┘
```

Note: All transitions are allowed (no restrictions). The sync between `done` and `completed` is the only automatic behavior.

---

### Modified: Comment

**New Fields**:
- `parent_id` (integer, nullable, FK → comments.id): References the parent comment for replies. NULL = top-level comment.
- `edited_at` (datetime, nullable): Set when comment body is updated. Presence indicates "(edited)" display.

**New Associations**:
- `belongs_to :parent, class_name: "Comment", optional: true`
- `has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy`
- `has_many :comment_likes, dependent: :destroy`

**Validation Changes**:
- Add: `validate :nesting_depth_limit` — ensures `parent.parent_id.nil?` (max 1 level of nesting)

**New Scopes**:
- `scope :top_level, -> { where(parent_id: nil) }`
- `scope :ordered, -> { order(created_at: :asc) }`

**Index**: `index :parent_id`

---

### New: CommentLike

**Fields**:
- `id` (primary key)
- `comment_id` (integer, FK → comments.id, NOT NULL)
- `user_id` (integer, FK → users.id, NOT NULL)
- `created_at`, `updated_at` (timestamps)

**Associations**:
- `belongs_to :comment, counter_cache: :likes_count`
- `belongs_to :user`

**Validations**:
- Uniqueness: `[comment_id, user_id]` (model + DB unique index)

**Index**: `unique index on [comment_id, user_id]`

---

### Modified: Comment (additional field for counter cache)

**New Fields**:
- `likes_count` (integer, default: 0): Counter cache for comment likes.

---

### New: NotifyPerson

**Fields**:
- `id` (primary key)
- `todo_item_id` (integer, FK → todo_items.id, NOT NULL)
- `user_id` (integer, FK → users.id, NOT NULL)
- `created_at`, `updated_at` (timestamps)

**Associations**:
- `belongs_to :todo_item`
- `belongs_to :user`

**Validations**:
- Uniqueness: `[todo_item_id, user_id]` (model + DB unique index)

**Index**: `unique index on [todo_item_id, user_id]`

---

## Migration Summary

### Migration 1: Add on_hold status and urgent priority to todo_items
- No schema change needed (status/priority are string columns, not DB enums)
- Data migration: rename `medium` → `normal` in existing records

### Migration 2: Add reply and edit support to comments
- Add `parent_id` (integer, nullable) to comments
- Add `edited_at` (datetime, nullable) to comments
- Add `likes_count` (integer, default: 0) to comments
- Add index on `parent_id`

### Migration 3: Create comment_likes table
- Create `comment_likes` table with `comment_id`, `user_id`, timestamps
- Add unique index on `[comment_id, user_id]`

### Migration 4: Create notify_people table
- Create `notify_people` table with `todo_item_id`, `user_id`, timestamps
- Add unique index on `[todo_item_id, user_id]`

---

## Relationship Diagram

```
User ─────────────────────────────────────────────┐
 │                                                 │
 │ has_many                                        │
 ▼                                                 │
TodoList                                           │
 │                                                 │
 │ has_many                                        │
 ▼                                                 │
TodoItem ──── has_rich_text :notes (via Lexxy)     │
 │   │   │                                         │
 │   │   │ has_many_attached :files                │
 │   │   │                                         │
 │   │   ├── has_many → ChecklistItem              │
 │   │   │                                         │
 │   │   ├── has_many → Comment ◄── belongs_to User│
 │   │   │    │   │                                │
 │   │   │    │   ├── has_many → Comment (replies)  │
 │   │   │    │   │    └── parent_id → Comment     │
 │   │   │    │   │                                │
 │   │   │    │   └── has_many → CommentLike       │
 │   │   │    │        └── belongs_to User ────────┘
 │   │   │    │
 │   │   ├── has_many → NotifyPerson
 │   │   │    └── belongs_to User
 │   │   │
 │   │   └── has_many → ItemTag → belongs_to Tag
 │   │
 │   └── belongs_to → User (assigned_to, optional)
 │
 └── belongs_to → TodoSection (optional)
```

## Eager Loading Requirements

The detail screen must eager-load to prevent N+1 queries:

```ruby
@todo_item = @todo_list.todo_items
  .includes(
    :rich_text_notes,
    :tags,
    :checklist_items,
    :files_attachments,    # Active Storage
    :assigned_to,
    :notify_people,
    comments: [:user, :comment_likes, replies: [:user, :comment_likes]]
  )
  .find(params[:id])
```
