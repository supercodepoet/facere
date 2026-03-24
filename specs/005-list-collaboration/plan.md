# Implementation Plan: List Collaboration

**Branch**: `005-list-collaboration` | **Date**: 2026-03-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-list-collaboration/spec.md`

## Summary

Add list-level collaboration to Facere. Users invite collaborators by email (token-based link acceptance). Two roles: editor (full item + section CRUD) and viewer (read-only + comments). Real-time broadcasting via ActionCable/Turbo Streams. Email notifications for invitations and item completions. Shared lists appear in sidebar under "Shared with me" section. Maximum 25 collaborators per list.

## Technical Context

**Language/Version**: Ruby 4.0.1 / Rails 8.1.2
**Primary Dependencies**: Hotwire (Turbo Drive, Turbo Frames, Turbo Streams, Stimulus), ActionCable (already configured — connection + auth in place, no channels yet), Action Mailer (existing mailers for email verification and password reset), Font Awesome Pro (CDN kit), Lexxy, Active Storage, ActionText
**Storage**: SQLite (all environments), Solid Cable (production ActionCable adapter)
**Testing**: Minitest + Capybara + Selenium
**Target Platform**: Web (responsive — desktop + mobile)
**Project Type**: Web application (Rails monolith)
**Performance Goals**: Real-time broadcasts within 2 seconds (SC-009), email delivery within 60 seconds (SC-008)
**Constraints**: Max 25 collaborators per list, email-only notifications (no in-app notification UI), two roles only (editor/viewer)
**Scale/Scope**: Small-team collaboration (1–25 people per list)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Vanilla Rails First | **PASS** | ActionCable (built-in) for WebSockets, Turbo Streams for broadcasting, Action Mailer for emails. No external JS frameworks. |
| II. Library-First | **PASS** | Using all Rails built-ins: ActionCable, Turbo Streams broadcasting, Action Mailer, `generates_token_for`. No new gems needed. |
| III. Joyful User Experience | **PASS** | Font Awesome Pro icons for collaboration panel, role pickers, avatar stacks. Pen file designs will be updated. |
| IV. Clean Architecture & DDD | **PASS** | New models: ListCollaborator, ListInvitation. Service objects for invitation acceptance. Authorization via concern. Eager loading for collaborator lists. |
| V. Code Quality & Readability | **PASS** | Authorization concern keeps controllers thin. Models handle role logic. Methods < 50 lines. |
| VI. Separation of Concerns | **PASS** | Authorization in concern, invitation logic in model/mailer, broadcasting in model callbacks/channels. |
| VII. Simplicity & YAGNI | **PASS** | Two roles (not granular permissions), email-only notifications (not in-app system), list-level sharing (not workspaces). |

**All gates pass. No violations to track.**

## Project Structure

### Documentation (this feature)

```text
specs/005-list-collaboration/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research
├── data-model.md        # Phase 1 data model
├── quickstart.md        # Phase 1 quickstart guide
├── contracts/           # Phase 1 interface contracts
│   └── routes.md        # New routes and URL structure
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
app/
├── models/
│   ├── list_collaborator.rb     # NEW: Collaboration membership
│   ├── list_invitation.rb       # NEW: Pending invitation
│   ├── todo_list.rb             # MODIFIED: collaborators association, access methods
│   ├── todo_item.rb             # MODIFIED: assigned_to supports multiple collaborators
│   ├── user.rb                  # MODIFIED: shared_lists association
│   └── comment.rb               # UNCHANGED: already supports multi-user
├── controllers/
│   ├── concerns/
│   │   ├── authentication.rb    # UNCHANGED
│   │   └── list_authorization.rb  # NEW: Role-based access control concern
│   ├── list_collaborators_controller.rb  # NEW: Manage collaborators
│   ├── list_invitations_controller.rb    # NEW: Send/accept/cancel invitations
│   ├── todo_lists_controller.rb          # MODIFIED: Show shared lists, authorize
│   ├── todo_items_controller.rb          # MODIFIED: Authorize edits by role
│   ├── todo_sections_controller.rb       # MODIFIED: Authorize by role
│   ├── comments_controller.rb            # MODIFIED: Allow viewer comments
│   ├── notify_people_controller.rb       # MODIFIED: Pick from collaborator pool
│   └── checklist_items_controller.rb     # MODIFIED: Authorize by role
├── channels/
│   └── application_cable/
│       └── connection.rb        # UNCHANGED: Already authenticates users (Turbo::StreamsChannel used for broadcasting — no custom channel needed)
├── mailers/
│   ├── collaboration_mailer.rb  # NEW: Invitation + completion emails
│   └── application_mailer.rb    # UNCHANGED
├── views/
│   ├── todo_lists/
│   │   ├── index.html.erb       # MODIFIED: Shared lists section
│   │   ├── show.html.erb        # MODIFIED: Collaboration header, role-based UI
│   │   ├── _sidebar.html.erb    # MODIFIED: "Shared with me" section
│   │   └── _collaboration_panel.html.erb  # NEW: Invite/manage collaborators
│   ├── list_invitations/
│   │   └── accept.html.erb      # NEW: Invitation acceptance page
│   ├── collaboration_mailer/
│   │   ├── invitation_email.html.erb      # NEW
│   │   ├── invitation_email.text.erb      # NEW
│   │   ├── item_completed_email.html.erb  # NEW
│   │   └── item_completed_email.text.erb  # NEW
│   └── shared/
│       └── _collaborator_avatars.html.erb # NEW: Avatar stack partial
├── javascript/
│   └── controllers/
│       └── collaboration_controller.js    # NEW: Collaboration panel Stimulus (turbo_stream_from handles ActionCable subscription automatically)
└── assets/
    └── stylesheets/
        └── collaboration.css              # NEW: Collaboration-specific styles

db/migrate/
├── XXXXXX_create_list_collaborators.rb                        # NEW
├── XXXXXX_create_list_invitations.rb                          # NEW
└── XXXXXX_create_item_assignees_and_remove_assigned_to.rb     # NEW: Multi-assignment support

config/
└── routes.rb                              # MODIFIED: Collaboration + invitation routes

test/
├── models/
│   ├── list_collaborator_test.rb          # NEW
│   └── list_invitation_test.rb            # NEW
├── controllers/
│   ├── list_collaborators_controller_test.rb  # NEW
│   └── list_invitations_controller_test.rb    # NEW
├── mailers/
│   └── collaboration_mailer_test.rb       # NEW
└── system/
    └── collaboration_test.rb              # NEW
```

**Structure Decision**: Follows existing Rails monolith convention. New models/controllers/views added alongside existing ones. Authorization extracted into a reusable concern. `Turbo::StreamsChannel` with signed stream names for broadcasting (no custom channel needed).

### Actual Files Created/Modified (Post-Implementation)

```text
# NEW files created
app/models/list_collaborator.rb
app/models/list_invitation.rb
app/models/item_assignee.rb
app/controllers/concerns/list_authorization.rb
app/controllers/list_invitations_controller.rb
app/controllers/list_collaborators_controller.rb
app/controllers/item_assignees_controller.rb
app/mailers/collaboration_mailer.rb
app/views/collaboration_mailer/invitation_email.html.erb
app/views/collaboration_mailer/invitation_email.text.erb
app/views/collaboration_mailer/item_completed_email.html.erb
app/views/collaboration_mailer/item_completed_email.text.erb
app/views/todo_lists/_collaboration_panel.html.erb
app/javascript/controllers/collaboration_controller.js
app/assets/stylesheets/collaboration.css
db/migrate/20260323183234_create_list_collaborators.rb
db/migrate/20260323183248_create_list_invitations.rb
db/migrate/20260323183304_create_item_assignees_and_remove_assigned_to.rb

# Test files created
test/models/list_collaborator_test.rb
test/models/list_invitation_test.rb
test/models/item_assignee_test.rb
test/models/todo_list_collaboration_test.rb
test/controllers/list_invitations_controller_test.rb
test/controllers/list_collaborators_controller_test.rb
test/controllers/item_assignees_controller_test.rb
test/controllers/collaboration_authorization_test.rb

# MODIFIED files
app/models/todo_list.rb          # +collaborator associations, role_for, all_members, at_collaborator_limit?
app/models/todo_item.rb          # assigned_to → item_assignees, broadcast_refresh_to, completion notifications
app/models/user.rb               # +shared_lists, item_assignees, sent_invitations associations
app/models/comment.rb            # +broadcast_refresh_to
app/models/todo_section.rb       # +broadcast_refresh_to
app/controllers/todo_lists_controller.rb    # +ListAuthorization, shared list queries, eager loading
app/controllers/todo_items_controller.rb    # +ListAuthorization, removed assigned_to_user_id param
app/controllers/todo_sections_controller.rb # +ListAuthorization
app/controllers/comments_controller.rb      # +ListAuthorization (list_access for create)
app/controllers/checklist_items_controller.rb # +ListAuthorization
app/controllers/notify_people_controller.rb   # +ListAuthorization, any-member selection
app/controllers/tags_controller.rb            # +ListAuthorization
app/controllers/attachments_controller.rb     # +ListAuthorization
app/controllers/registrations_controller.rb   # invitation auto-accept after signup
app/controllers/sessions_controller.rb        # invitation auto-accept after signin
app/views/todo_lists/show.html.erb            # collaboration panel, role-based UI, turbo_stream_from
app/views/todo_lists/_sidebar.html.erb        # "Shared with me" section
app/views/todo_lists/_todo_item.html.erb      # role-based controls, multi-assignee avatars
app/views/todo_lists/_section.html.erb        # role-based controls
app/views/todo_lists/index.html.erb           # shared lists grid
app/views/todo_lists/_list_card.html.erb      # shared-by label
app/views/todo_items/_assignees_card.html.erb # multi-assignee picker with add/remove
app/views/layouts/app.html.erb                # +collaboration.css
config/routes.rb                              # +collaborator/invitation/assignee routes
config/environments/development.rb            # +async job adapter, letter_opener_web
Gemfile                                       # +letter_opener_web
```

## Copilot Code Review Findings

Two review rounds. All findings addressed:

| Finding | Resolution |
|---------|-----------|
| ERB syntax `<%= if` in text template | Fixed: changed to `<% if` |
| Assignees card missing add/remove UI | Fixed: added member picker with POST/DELETE to item_assignees routes |
| N+1 on `item.assignees` in list view | Fixed: `includes(item_assignees: :user)` on sections and unsectioned items |
| `accept!` ignores collaborator limit | Fixed: added `at_collaborator_limit?` check inside transaction |
| `Current.user` nil in completion notifications | Fixed: added `return unless Current.user` guard |
| `destroy` can cancel non-pending invitations | Fixed: scoped to `status: "pending"` with `find_by!` |
| Duplicate Stimulus controller on panel | Fixed: removed `data-controller` from panel partial |
| Typos (ActionTex, collaboratiors, apart of, stray "A") | All fixed |
| No tests | Fixed: 99 new tests (models + controllers + authorization) |
| `deliver_now` blocks requests | Fixed: switched to `deliver_later` with async adapter |
| Misleading "inline" comment for async adapter | Fixed: updated comment |
| Role default missing when param omitted | Fixed: defaults to "editor" |
| `after_registration_url` dead code | Fixed: removed method, redirect to accepted list directly |
| macOS sed in settings.local.json | Ignored: auto-generated tool permissions, not portable config |

## Complexity Tracking

> No constitution violations. Table not needed.
