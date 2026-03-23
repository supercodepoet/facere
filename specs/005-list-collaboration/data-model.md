# Data Model: List Collaboration

**Feature**: 005-list-collaboration | **Date**: 2026-03-23

## New Tables

### list_collaborators

Represents an active collaboration membership between a user and a TODO list.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| todo_list_id | integer | FK → todo_lists.id, NOT NULL | The shared list |
| user_id | integer | FK → users.id, NOT NULL | The collaborator |
| role | string | NOT NULL, default: "editor" | "editor" or "viewer" |
| created_at | datetime | NOT NULL | When collaboration was accepted |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `UNIQUE (todo_list_id, user_id)` — A user can only be a collaborator once per list
- `(user_id)` — For querying "lists shared with me"

**Validations**:
- `role` must be in `%w[editor viewer]`
- `user_id` must not equal the list owner's `user_id` (owner is not stored as a collaborator)
- Unique constraint: one record per (todo_list_id, user_id)

**Associations**:
- `belongs_to :todo_list`
- `belongs_to :user`

### list_invitations

Represents a pending invitation to collaborate on a list.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| todo_list_id | integer | FK → todo_lists.id, NOT NULL | The list being shared |
| invited_by_id | integer | FK → users.id, NOT NULL | The owner who sent the invitation |
| email | string | NOT NULL | Invitee's email (normalized, lowercase) |
| role | string | NOT NULL, default: "editor" | Intended role: "editor" or "viewer" |
| status | string | NOT NULL, default: "pending" | "pending", "accepted", "cancelled", "expired" |
| accepted_at | datetime | NULL | When the invitation was accepted |
| expires_at | datetime | NOT NULL | 30 days from creation |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `UNIQUE (todo_list_id, email)` WHERE `status = 'pending'` — Only one pending invitation per email per list
- `(email)` — For looking up invitations when a new user registers
- `(status, expires_at)` — For expiration cleanup job

**Token generation**:
- Uses `generates_token_for :acceptance, expires_in: 30.days` keyed on `status` (token invalidates if status changes)

**Validations**:
- `email` must be present, valid format
- `role` must be in `%w[editor viewer]`
- `status` must be in `%w[pending accepted cancelled expired]`
- Cannot invite the list owner's email
- Cannot invite an email that already has an active collaboration on the list

**Associations**:
- `belongs_to :todo_list`
- `belongs_to :invited_by, class_name: "User"`

**State transitions**:
```
pending → accepted    (invitee clicks link)
pending → cancelled   (owner cancels)
pending → expired     (30 days pass, or cleanup job runs)
```

### item_assignees

Replaces the single `assigned_to_user_id` FK on `todo_items` with a many-to-many relationship.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | integer | PK, auto-increment | |
| todo_item_id | integer | FK → todo_items.id, NOT NULL | |
| user_id | integer | FK → users.id, NOT NULL | |
| created_at | datetime | NOT NULL | |
| updated_at | datetime | NOT NULL | |

**Indexes**:
- `UNIQUE (todo_item_id, user_id)` — A user can only be assigned once per item

**Validations**:
- Unique constraint: one record per (todo_item_id, user_id)

**Associations**:
- `belongs_to :todo_item`
- `belongs_to :user`

## Modified Tables

### todo_items

- **Remove column**: `assigned_to_user_id` (replaced by `item_assignees` join table)
- **Migration strategy**:
  1. Create `item_assignees` table
  2. Migrate existing `assigned_to_user_id` data to `item_assignees` records
  3. Remove `assigned_to_user_id` column

### todo_lists (no schema change)

No column changes. New associations added at model level:
- `has_many :list_collaborators, dependent: :destroy`
- `has_many :collaborators, through: :list_collaborators, source: :user`
- `has_many :list_invitations, dependent: :destroy`

### users (no schema change)

No column changes. New associations added at model level:
- `has_many :list_collaborators, dependent: :destroy`
- `has_many :shared_lists, through: :list_collaborators, source: :todo_list`
- `has_many :sent_invitations, class_name: "ListInvitation", foreign_key: :invited_by_id, dependent: :destroy`

## Entity Relationship Diagram

```
┌──────────┐       ┌───────────────────┐       ┌──────────┐
│  users   │──1:N──│ list_collaborators │──N:1──│todo_lists│
│          │       │                   │       │          │
│          │       │ - role            │       │ - user_id│ (owner)
│          │       │ - user_id         │       │          │
│          │       │ - todo_list_id    │       │          │
└──────────┘       └───────────────────┘       └──────────┘
     │                                              │
     │              ┌───────────────────┐           │
     │──1:N────────│ list_invitations   │──N:1──────│
     │ (invited_by) │                   │           │
     │              │ - email           │           │
     │              │ - role            │           │
     │              │ - status          │           │
     │              │ - expires_at      │           │
     │              └───────────────────┘           │
     │                                              │
     │              ┌───────────────────┐    ┌──────────────┐
     │──1:N────────│ item_assignees    │──N:1│  todo_items   │
     │              │                   │    │               │
     │              │ - user_id         │    │               │
     │              │ - todo_item_id    │    │               │
     │              └───────────────────┘    └───────────────┘
     │                                              │
     │              ┌───────────────────┐           │
     │──1:N────────│ notify_people     │──N:1───────│
     │              │ (existing)        │           │
     │              └───────────────────┘           │
     │                                              │
     │              ┌───────────────────┐           │
     │──1:N────────│ comments          │──N:1───────│
                    │ (existing)        │
                    └───────────────────┘
```

## Key Model Methods

### TodoList

```ruby
# Returns "owner", "editor", "viewer", or nil
def role_for(user)
  return "owner" if user_id == user.id
  list_collaborators.find_by(user_id: user.id)&.role
end

# All users with access (owner + collaborators)
def all_members
  User.where(id: [user_id] + list_collaborators.pluck(:user_id))
end

# Check collaborator count limit
def at_collaborator_limit?
  list_collaborators.count >= 25
end
```

### ListInvitation

```ruby
generates_token_for :acceptance, expires_in: 30.days do
  status  # Token invalidates when status changes
end

def accept!(user)
  transaction do
    update!(status: "accepted", accepted_at: Time.current)
    todo_list.list_collaborators.create!(user: user, role: role)
  end
end

def expired?
  expires_at < Time.current
end

def pending?
  status == "pending" && !expired?
end
```
