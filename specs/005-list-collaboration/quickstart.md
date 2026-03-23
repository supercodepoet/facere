# Quickstart: List Collaboration

**Feature**: 005-list-collaboration | **Date**: 2026-03-23

## Prerequisites

- Ruby 4.0.1, Rails 8.1.2 (already installed)
- SQLite (already configured)
- Existing Facere app running (`bin/dev`)
- At least two user accounts for testing collaboration

## Setup Steps

```bash
# 1. Switch to feature branch
git checkout 005-list-collaboration

# 2. Run new migrations
bin/rails db:migrate

# 3. Start development server
bin/dev
```

## Key Implementation Order

### Phase 1: Data Model + Authorization Foundation
1. Create `list_collaborators` migration and model
2. Create `list_invitations` migration and model
3. Create `item_assignees` migration and model (+ migrate `assigned_to_user_id` data)
4. Add associations to `TodoList`, `User`, `TodoItem`
5. Create `ListAuthorization` concern
6. Apply authorization to all existing controllers

### Phase 2: Invitation Flow
7. Create `CollaborationMailer` with `invitation_email`
8. Create `ListInvitationsController` (create, accept, destroy)
9. Add invitation acceptance routes
10. Handle unregistered user flow (token in session → auto-accept after sign-up)

### Phase 3: Collaboration UI
11. Update sidebar with "Shared with me" section
12. Update overview page with shared list cards
13. Create collaboration panel (invite, manage, remove)
14. Update list header with collaborator avatars
15. Update item assignment picker to show collaborator pool
16. Update notify-on-complete picker to show collaborator pool

### Phase 4: Role-Based Access Control
17. Implement viewer restrictions (disable editing controls)
18. Implement editor permissions (allow section management)
19. Test all authorization boundaries

### Phase 5: Real-Time Broadcasting
20. Add `turbo_stream_from` to list and item views
21. Add broadcast callbacks to models (items, comments, sections)
22. Add completion email notifications (`CollaborationMailer#item_completed_email`)

### Phase 6: Polish + Testing
23. Update .pen design files with collaboration UI screens
24. Full test suite (models, controllers, system tests)
25. Security tests (authorization, parameter injection, cross-list access)

## Testing Collaboration Locally

```bash
# Run all tests
bin/rails test
bin/rails test:system

# Manual testing: open two browser windows (one regular, one incognito)
# Log in as different users to test real-time collaboration
```

## Key Files to Understand

| File | Purpose |
|------|---------|
| `app/models/list_collaborator.rb` | Collaboration membership |
| `app/models/list_invitation.rb` | Pending invitation + token |
| `app/controllers/concerns/list_authorization.rb` | Role-based access control |
| `app/mailers/collaboration_mailer.rb` | Invitation + completion emails |
| `app/views/todo_lists/_sidebar.html.erb` | Shared lists in sidebar |
| `app/views/todo_lists/_collaboration_panel.html.erb` | Invite/manage UI |
