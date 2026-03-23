# Routes Contract: List Collaboration

**Feature**: 005-list-collaboration | **Date**: 2026-03-23

## New Routes

### List Collaborators (nested under todo_lists)

```ruby
resources :todo_lists, path: "lists" do
  # ... existing item/section routes ...

  resources :collaborators, controller: "list_collaborators", only: [:index, :update, :destroy] do
    collection do
      # Owner views the collaboration panel
      # GET /lists/:todo_list_id/collaborators
    end
    member do
      # Owner changes a collaborator's role
      # PATCH /lists/:todo_list_id/collaborators/:id
      # Owner removes a collaborator
      # DELETE /lists/:todo_list_id/collaborators/:id
    end
  end

  resource :leave, controller: "list_collaborators", only: [] do
    # Collaborator leaves voluntarily
    # DELETE /lists/:todo_list_id/leave
    delete :destroy, action: :leave
  end

  resources :invitations, controller: "list_invitations", only: [:create, :destroy] do
    collection do
      # Owner sends a new invitation
      # POST /lists/:todo_list_id/invitations
    end
    member do
      # Owner cancels a pending invitation
      # DELETE /lists/:todo_list_id/invitations/:id
    end
  end
end
```

### Invitation Acceptance (top-level, not nested)

```ruby
# Accept an invitation via token link from email
# GET /invitations/:token/accept
get "invitations/:token/accept", to: "list_invitations#accept", as: :accept_invitation
```

## Route Summary

| Method | Path | Controller#Action | Auth | Role |
|--------|------|-------------------|------|------|
| GET | /lists/:id/collaborators | list_collaborators#index | Yes | Owner |
| PATCH | /lists/:id/collaborators/:id | list_collaborators#update | Yes | Owner |
| DELETE | /lists/:id/collaborators/:id | list_collaborators#destroy | Yes | Owner |
| DELETE | /lists/:id/leave | list_collaborators#leave | Yes | Any collaborator |
| POST | /lists/:id/invitations | list_invitations#create | Yes | Owner |
| DELETE | /lists/:id/invitations/:id | list_invitations#destroy | Yes | Owner |
| GET | /invitations/:token/accept | list_invitations#accept | No* | Token-bearer |

*The accept route allows unauthenticated access. If the user is not logged in, they are redirected to sign-in (or sign-up for new users) with the token preserved in the session. After authentication, the invitation is auto-accepted.

## Modified Existing Routes

No changes to existing route structure. All existing `todo_lists`, `todo_items`, `todo_sections`, `comments`, `checklist_items`, `tags`, `attachments`, and `notify_people` routes remain unchanged. Authorization is enforced at the controller level, not the routing level.

## URL Examples

```
# Collaboration panel (Turbo Frame)
GET /lists/42/collaborators

# Invite someone
POST /lists/42/invitations
  params: { invitation: { email: "jane@example.com", role: "editor" } }

# Change role
PATCH /lists/42/collaborators/7
  params: { collaborator: { role: "viewer" } }

# Remove collaborator
DELETE /lists/42/collaborators/7

# Leave a list
DELETE /lists/42/leave

# Cancel pending invitation
DELETE /lists/42/invitations/12

# Accept invitation (from email link)
GET /invitations/eyJfcmFpbHMiOns.../accept
```
