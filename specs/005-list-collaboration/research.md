# Research: List Collaboration

**Feature**: 005-list-collaboration | **Date**: 2026-03-23

## 1. ActionCable Broadcasting with Turbo Streams

**Decision**: Use `Turbo::StreamsChannel` (built into turbo-rails) for per-list broadcasting. No custom ActionCable channel class needed.

**Rationale**: Rails 8.1 + turbo-rails provides `turbo_stream_from` helper that auto-subscribes clients to a Turbo Streams broadcast channel. Models can call `broadcast_replace_to`, `broadcast_append_to`, etc. This is the vanilla Rails approach — no custom channel code required.

**Implementation pattern**:
- In views: `<%= turbo_stream_from @todo_list, :collaborators %>`
- In models/controllers: `Turbo::StreamsChannel.broadcast_replace_to([todo_list, :collaborators], target: ..., partial: ...)`
- Authorization: Override `Turbo::StreamsChannel` verification to check list access (collaborator or owner)

**Alternatives considered**:
- Custom ActionCable channel: More control but duplicates what turbo-rails already provides. Would require manual JSON serialization and client-side DOM updates.
- Polling: Simple but adds latency and server load. Rejected per user's choice of real-time (Option A).

## 2. Token-Based Invitation Acceptance

**Decision**: Use Rails `generates_token_for` on the ListInvitation model for secure, expiring invitation tokens.

**Rationale**: The existing codebase already uses `generates_token_for` on User for email verification and password reset. Consistent pattern, built-in Rails feature, no new dependencies.

**Implementation pattern**:
- `ListInvitation` uses `generates_token_for :acceptance, expires_in: 30.days`
- Invitation email contains link: `/invitations/:token/accept`
- Token resolves to the invitation record; acceptance creates a `ListCollaborator` record
- For unregistered users: token is stored in session during sign-up, auto-accepted after registration

**Alternatives considered**:
- UUID-based tokens (manual): Works but lacks built-in expiration. `generates_token_for` handles expiry automatically.
- Signed Global IDs: Also built-in but more complex for this use case. `generates_token_for` is simpler and already established in the codebase.

## 3. Authorization Pattern

**Decision**: Extract a `ListAuthorization` concern for controllers, using a `current_list_role` helper method.

**Rationale**: Multiple controllers need to check if the current user has access to a list and what role they have. A concern keeps this DRY. The pattern follows Rails conventions (like the existing `Authentication` concern).

**Implementation pattern**:
```ruby
# app/controllers/concerns/list_authorization.rb
module ListAuthorization
  extend ActiveSupport::Concern

  private

  def authorize_list_access!
    return if current_list_role.present?
    head :not_found  # 404 per constitution security rules
  end

  def authorize_editor!
    return if current_list_role.in?(%w[owner editor])
    head :not_found
  end

  def current_list_role
    @current_list_role ||= @todo_list&.role_for(Current.user)
  end
end
```

- `TodoList#role_for(user)` returns "owner", "editor", "viewer", or nil
- Controllers call `before_action :authorize_list_access!` and `before_action :authorize_editor!` as needed
- Returns 404 (not 403) per constitution security rules

**Alternatives considered**:
- Pundit gem: Full-featured but overkill for two roles. Violates Library-First only when simpler built-in solutions exist.
- Per-controller authorization: Works but leads to duplication across 6+ controllers.

## 4. Sidebar and Overview Updates

**Decision**: Modify sidebar to show two sections ("My Lists" and "Shared with me"). Modify overview to visually distinguish shared lists.

**Rationale**: The sidebar partial (`_sidebar.html.erb`) currently shows only `Current.user.todo_lists`. Adding a second query for shared lists and rendering them in a separate section is straightforward. The overview page (`index.html.erb`) uses `_list_card` partial — add a sharing badge and owner avatar.

**Implementation pattern**:
- `User#shared_lists` → `TodoList.joins(:list_collaborators).where(list_collaborators: { user_id: id })`
- Sidebar: Two `<ul>` sections with different headings
- Overview: `_list_card` partial gets a conditional `shared` flag for badge rendering
- Controller: `TodoListsController#index` loads both `@todo_lists` and `@shared_lists`

**Alternatives considered**:
- Single merged list with icons: Confusing — users can't quickly distinguish owned vs shared.
- Tabs (toggle between owned/shared): Hides content unnecessarily. Both sections should be visible simultaneously.

## 5. Email Delivery for Notifications

**Decision**: Use Action Mailer with `deliver_later` (Active Job via Solid Queue) for all collaboration emails.

**Rationale**: The app already uses Active Job (Solid Queue) for background processing. `deliver_later` is the standard Rails pattern for async email delivery. Two new mailer actions: `invitation_email` and `item_completed_email`.

**Implementation pattern**:
- `CollaborationMailer#invitation_email(invitation)` — sent when owner invites someone
- `CollaborationMailer#item_completed_email(todo_item, completed_by_user, recipient_user)` — sent to each person on the notify list
- Triggered from controller (invitation) and model callback (completion)
- Uses `deliver_later` to avoid blocking the request

**Alternatives considered**:
- Inline delivery (`deliver_now`): Blocks the request. Bad UX for completion notifications where multiple emails may be sent.
- Third-party email service gem: Unnecessary — Action Mailer + Solid Queue handles this.

## 6. Multi-User Assignment (assigned_to)

**Decision**: Keep the existing single `assigned_to_user_id` column on `todo_items`. The current data model already supports assigning one user, and the UI design shows individual assignees. For multiple assignments, use the existing pattern where the picker shows collaborators.

**Rationale**: The spec says "assign one or more collaborators" but the existing `assigned_to` is a single `belongs_to`. Looking at the UI design, the item detail shows individual user avatars under "Assigned to." The existing model and UI pattern works — editors just now pick from the collaborator pool instead of only themselves. If true multi-assignment is needed later, a join table can be added.

**Update**: After re-reading the spec (User Story 3: "an editor assigns two collaborators"), multi-assignment IS required. We need to transition from `assigned_to_user_id` (single FK) to a join table approach similar to `notify_people`.

**Revised Decision**: Create an `item_assignees` join table (todo_item_id, user_id) to support multiple assignees per item. Deprecate the `assigned_to_user_id` column via migration (migrate existing data, then remove column).

**Alternatives considered**:
- Keep single assignment: Doesn't satisfy spec requirement for multiple assignees.
- Array column: Not supported well in SQLite. Join table is the Rails convention.

## 7. Turbo Stream Authorization for Broadcasts

**Decision**: Use signed stream names via `turbo_stream_from` which automatically signs the stream name, preventing unauthorized subscriptions.

**Rationale**: `turbo_stream_from` in turbo-rails uses signed stream names by default. The stream name includes the model's global ID, which is cryptographically signed. Only users who receive the signed token (via the rendered HTML) can subscribe. Since the view is only rendered for users with list access, unauthorized users never receive the signed token.

**Implementation pattern**:
- View renders `<%= turbo_stream_from @todo_list, :updates %>` only for authorized users
- The helper generates a signed stream name token
- ActionCable verifies the signature on subscription
- No custom channel authorization code needed

**Alternatives considered**:
- Custom channel with `#subscribed` authorization: Works but duplicates the access check already done at render time. The signed stream name approach is more Rails-idiomatic.
