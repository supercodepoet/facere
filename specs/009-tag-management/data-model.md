# Data Model: Tag Management

**Feature**: 009-tag-management
**Date**: 2026-03-24

## Entities

### Tag (existing — no schema changes)

| Field  | Type   | Constraints                                          |
|--------|--------|------------------------------------------------------|
| id     | integer| Primary key                                          |
| name   | string | Required, max 50 chars, unique per user (case-insensitive) |
| color  | string | Optional, 6-digit hex format (#RRGGBB)               |
| user_id| integer| Foreign key → User, required                         |

**Relationships**:
- `belongs_to :user`
- `has_many :item_tags, dependent: :destroy`
- `has_many :todo_items, through: :item_tags`

**Validations**:
- `name`: presence, length max 50, uniqueness scoped to user_id (case-insensitive)
- `color`: hex format `/\A#[0-9a-fA-F]{6}\z/`, allow_blank

### ItemTag (existing — no schema changes)

| Field       | Type    | Constraints                        |
|-------------|---------|-------------------------------------|
| id          | integer | Primary key                         |
| todo_item_id| integer | Foreign key → TodoItem, required    |
| tag_id      | integer | Foreign key → Tag, required         |

**Relationships**:
- `belongs_to :todo_item`
- `belongs_to :tag`

**Validations**:
- `tag_id`: uniqueness scoped to `todo_item_id`

## Schema Changes

**None required.** The existing schema fully supports the tag management feature. The Tag model already has `name`, `color`, and `user_id` columns. The ItemTag join table already exists.

## State Transitions

Tags have no lifecycle states — they are simply created, updated, or deleted. No state machine needed.

## Query Patterns

| Query                          | Purpose                            | Scope                 |
|--------------------------------|------------------------------------|-----------------------|
| `Current.user.tags`            | List all user's tags               | Tag editor dropdown   |
| `Current.user.tags.where("LOWER(name) LIKE ?", "%#{q}%")` | Search tags (server-side fallback) | Search (if needed) |
| `@todo_item.tags`              | Tags applied to current item       | Checkmark display     |
| `@todo_item.item_tags.find_by(tag_id:)` | Toggle tag off item     | Remove tag            |
| `@todo_item.item_tags.create!(tag:)` | Toggle tag on item          | Add tag               |
| `Current.user.tags.find(id)`   | Find tag for edit/delete           | Tag CRUD              |
