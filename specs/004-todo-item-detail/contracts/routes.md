# Route Contracts: TODO Item Detail Screen

**Branch**: `004-todo-item-detail` | **Date**: 2026-03-22

## Existing Routes (unchanged)

```
GET    /lists/:todo_list_id/items/:id          → todo_items#show
PATCH  /lists/:todo_list_id/items/:id          → todo_items#update
DELETE /lists/:todo_list_id/items/:id          → todo_items#destroy
PATCH  /lists/:todo_list_id/items/:id/toggle   → todo_items#toggle

POST   /lists/:todo_list_id/items/:todo_item_id/checklist      → checklist_items#create
PATCH  /lists/:todo_list_id/items/:todo_item_id/checklist/:id  → checklist_items#update
DELETE /lists/:todo_list_id/items/:todo_item_id/checklist/:id  → checklist_items#destroy
PATCH  /lists/:todo_list_id/items/:todo_item_id/checklist/:id/toggle → checklist_items#toggle

POST   /lists/:todo_list_id/items/:todo_item_id/attachments    → attachments#create
DELETE /lists/:todo_list_id/items/:todo_item_id/attachments/:id → attachments#destroy

POST   /lists/:todo_list_id/items/:todo_item_id/tags           → tags#create
DELETE /lists/:todo_list_id/items/:todo_item_id/tags/:id       → tags#destroy

POST   /lists/:todo_list_id/items/:todo_item_id/comments       → comments#create
DELETE /lists/:todo_list_id/items/:todo_item_id/comments/:id   → comments#destroy
```

## New Routes

```
# Comment editing
PATCH  /lists/:todo_list_id/items/:todo_item_id/comments/:id   → comments#update

# Comment likes (toggle)
POST   /lists/:todo_list_id/items/:todo_item_id/comments/:comment_id/likes   → comment_likes#create
DELETE /lists/:todo_list_id/items/:todo_item_id/comments/:comment_id/likes/:id → comment_likes#destroy

# Notify on complete people
POST   /lists/:todo_list_id/items/:todo_item_id/notify_people       → notify_people#create
DELETE /lists/:todo_list_id/items/:todo_item_id/notify_people/:id   → notify_people#destroy
```

## Route Definitions (for config/routes.rb)

```ruby
resources :comments, only: [:create, :update, :destroy] do
  resources :likes, only: [:create, :destroy], controller: "comment_likes"
end
resources :notify_people, only: [:create, :destroy]
```

## Request/Response Contracts

### PATCH /comments/:id (update)
**Request**: `{ comment: { body: "Updated text" } }`
**Response**: Turbo Stream replacing the comment frame

### POST /comments/:comment_id/likes (create)
**Request**: Empty body (current user implied)
**Response**: Turbo Stream replacing the like button area

### DELETE /comments/:comment_id/likes/:id (destroy)
**Request**: Empty body
**Response**: Turbo Stream replacing the like button area

### POST /notify_people (create)
**Request**: `{ notify_person: { user_id: <current_user_id> } }` (server-enforced)
**Response**: Turbo Stream appending to notify list

### DELETE /notify_people/:id (destroy)
**Request**: Empty body
**Response**: Turbo Stream removing from notify list

### PATCH /items/:id (update — status/priority changes)
**Request**: `{ todo_item: { status: "in_progress" } }` or `{ todo_item: { priority: "urgent" } }`
**Response**: Turbo Stream replacing status/priority cards and header badges
