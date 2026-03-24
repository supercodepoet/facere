# Tasks: List Collaboration

**Input**: Design documents from `/specs/005-list-collaboration/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/routes.md, research.md, quickstart.md

**Tests**: Not explicitly requested in spec. Test tasks omitted. Add via `/speckit.tasks` with test flag if needed.

**Organization**: Tasks grouped by user story for independent implementation. 8 user stories mapped across 12 phases.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1–US8) this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database migrations and new model files that multiple stories depend on

- [x] T001 Create migration for list_collaborators table in db/migrate/XXXXXX_create_list_collaborators.rb (columns: todo_list_id, user_id, role with default "editor", timestamps; unique index on [todo_list_id, user_id]; index on user_id)
- [x] T002 Create migration for list_invitations table in db/migrate/XXXXXX_create_list_invitations.rb (columns: todo_list_id, invited_by_id, email, role with default "editor", status with default "pending", accepted_at, expires_at, timestamps; unique index on [todo_list_id, email] where status=pending; index on email; index on [status, expires_at])
- [x] T003 Create migration for item_assignees table and remove assigned_to_user_id in db/migrate/XXXXXX_create_item_assignees_and_remove_assigned_to.rb (create item_assignees with todo_item_id, user_id, timestamps, unique index on [todo_item_id, user_id]; migrate existing assigned_to_user_id data to item_assignees; remove assigned_to_user_id column from todo_items)
- [x] T004 Run migrations with bin/rails db:migrate

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, authorization, and associations that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Create ListCollaborator model in app/models/list_collaborator.rb (belongs_to :todo_list, belongs_to :user; validates role inclusion in %w[editor viewer]; validates uniqueness of user_id scoped to todo_list_id; validate user is not the list owner)
- [x] T006 [P] Create ListInvitation model in app/models/list_invitation.rb (belongs_to :todo_list, belongs_to :invited_by class User; generates_token_for :acceptance expires_in 30.days keyed on status; validates email presence/format, role inclusion, status inclusion; methods: accept!(user), expired?, pending?; normalizes email)
- [x] T007 [P] Create ItemAssignee model in app/models/item_assignee.rb (belongs_to :todo_item, belongs_to :user; validates uniqueness of user_id scoped to todo_item_id)
- [x] T008 Add collaboration associations to TodoList model in app/models/todo_list.rb (has_many :list_collaborators dependent :destroy; has_many :collaborators through :list_collaborators source :user; has_many :list_invitations dependent :destroy; add methods: role_for(user), all_members, at_collaborator_limit?)
- [x] T009 Add shared_lists association to User model in app/models/user.rb (has_many :list_collaborators dependent :destroy; has_many :shared_lists through :list_collaborators source :todo_list; has_many :item_assignees dependent :destroy; has_many :sent_invitations class ListInvitation foreign_key :invited_by_id dependent :destroy)
- [x] T010 Update TodoItem model in app/models/todo_item.rb (remove belongs_to :assigned_to; add has_many :item_assignees dependent :destroy; add has_many :assignees through :item_assignees source :user; update any methods that referenced assigned_to)
- [x] T011 Create ListAuthorization concern in app/controllers/concerns/list_authorization.rb (methods: authorize_list_access!, authorize_editor!, authorize_owner!, current_list_role; returns 404 for unauthorized per constitution; helper method list_editor? and list_viewer? for views)
- [x] T012 Apply ListAuthorization to TodoListsController in app/controllers/todo_lists_controller.rb (include ListAuthorization; update set_todo_list to find across owned AND shared lists; add before_action :authorize_list_access! for show; add before_action :authorize_owner! for edit/update/destroy; update index to load @shared_lists alongside @todo_lists)
- [x] T013 Apply ListAuthorization to TodoItemsController in app/controllers/todo_items_controller.rb (include ListAuthorization; add before_action :authorize_list_access! for show; add before_action :authorize_editor! for create/update/destroy/toggle/archive/move/copy/reorder; update assignment handling to use item_assignees instead of assigned_to_user_id)
- [x] T014 Apply ListAuthorization to TodoSectionsController in app/controllers/todo_sections_controller.rb (include ListAuthorization; add before_action :authorize_editor! for create/update/destroy/archive/move/reorder)
- [x] T015 Apply ListAuthorization to CommentsController in app/controllers/comments_controller.rb (include ListAuthorization; add before_action :authorize_list_access! for create — both editors and viewers can comment; keep existing author-only check for update/destroy)
- [x] T016 Apply ListAuthorization to ChecklistItemsController in app/controllers/checklist_items_controller.rb (include ListAuthorization; add before_action :authorize_editor! for all actions)
- [x] T017 Apply ListAuthorization to NotifyPeopleController in app/controllers/notify_people_controller.rb (include ListAuthorization; add before_action :authorize_editor! for create/destroy; update to allow selecting any collaborator, not just Current.user)
- [x] T018 Update TagsController in app/controllers/tags_controller.rb (include ListAuthorization; add before_action :authorize_editor! for create/destroy)
- [x] T019 Update AttachmentsController in app/controllers/attachments_controller.rb (include ListAuthorization; add before_action :authorize_editor! for create/destroy)
- [x] T019a Add expiration scope and status handling to ListInvitation model in app/models/list_invitation.rb (add scope :active, -> { where(status: "pending").where("expires_at > ?", Time.current) }; add method mark_expired! to update status to "expired"; use .active scope everywhere pending invitations are queried — ListInvitationsController#create duplicate check, collaboration panel display)

**Checkpoint**: Foundation ready — all existing controllers enforce list-level authorization. User story implementation can begin.

---

## Phase 3: User Story 1 — Invite a Collaborator to a List (Priority: P1) 🎯 MVP

**Goal**: List owner can invite collaborators by email. Invitee clicks a link in the email to accept. Pending invitations are visible in a collaboration panel.

**Independent Test**: Have one user invite another by email, click the acceptance link, and verify the shared list appears in the invitee's sidebar.

### Implementation for User Story 1

- [x] T020 [P] [US1] Create CollaborationMailer with invitation_email action in app/mailers/collaboration_mailer.rb (accepts ListInvitation; renders invitation link with token; includes list name, inviter name, role)
- [x] T021 [P] [US1] Create invitation email views in app/views/collaboration_mailer/invitation_email.html.erb and app/views/collaboration_mailer/invitation_email.text.erb (styled email with accept button/link, list info, inviter info)
- [x] T022 [US1] Add invitation and acceptance routes to config/routes.rb (nested under todo_lists: resources :invitations controller list_invitations only [:create, :destroy]; top-level: get "invitations/:token/accept" to list_invitations#accept)
- [x] T023 [US1] Create ListInvitationsController in app/controllers/list_invitations_controller.rb (create: owner sends invitation, validates email, checks limit of 25, creates ListInvitation, sends CollaborationMailer.invitation_email via deliver_later; accept: resolves token, creates ListCollaborator, redirects to list; destroy: owner cancels pending invitation; handle unregistered users by storing token in session)
- [x] T024 [US1] Update RegistrationsController in app/controllers/registrations_controller.rb (after successful registration, check session for pending invitation token; if present, auto-accept the invitation)
- [x] T025 [US1] Create collaboration panel partial in app/views/todo_lists/_collaboration_panel.html.erb (shows current collaborators with roles and avatars, pending invitations with cancel option, invite form with email input and role picker using a standard `<select>` element; only visible to owner)
- [x] T026 [US1] Create collaboration Stimulus controller in app/javascript/controllers/collaboration_controller.js (toggle panel visibility, handle invite form submission via Turbo, display validation errors inline)
- [x] T027 [US1] Add collaboration panel trigger button to list header in app/views/todo_lists/show.html.erb (share/people icon button next to existing action buttons; opens collaboration panel; only render for owner)
- [x] T028 [US1] Create collaboration panel styles in app/assets/stylesheets/collaboration.css (panel layout, collaborator list items, invite form, pending invitation items, role badges)
- [x] T029 [US1] Add stylesheet link for collaboration.css in app/views/layouts/app.html.erb

**Checkpoint**: User Story 1 complete — owners can invite by email, invitees can accept via link, collaboration panel shows members and pending invitations.

---

## Phase 4: User Story 2 — Collaborate on Items as an Editor (Priority: P1)

**Goal**: Editor-role collaborators can create, edit, complete, archive, and reorder items and sections on shared lists, identical to the owner experience (minus list deletion and collaborator management).

**Independent Test**: Invite a user as editor, verify they can create items, change status/priority, edit notes, manage tags, and manage sections on the shared list.

### Implementation for User Story 2

- [x] T030 [US2] Update todo_lists/show.html.erb to conditionally show/hide owner-only controls (delete list button, collaboration panel trigger only for owner; Add Item, Add Section buttons visible for editors and owner; use current_list_role helper)
- [x] T031 [US2] Update todo_lists/_todo_item.html.erb to conditionally render edit controls based on role (context menu, drag handle only for editors/owner; checkbox toggle for editors/owner; link always visible)
- [x] T032 [US2] Update todo_lists/_section.html.erb to conditionally render section management controls based on role (section context menu, add item button, drag handle only for editors/owner)
- [x] T033 [US2] Update todo_items/show.html.erb to conditionally disable editing controls for non-editors (status picker, priority picker, due date, tag management, checklist management, note editing, file upload — all gated on editor/owner role; comments always enabled)
- [x] T034 [US2] Add helper methods to ApplicationHelper or use view locals to expose current_list_role, list_editor?, list_owner? to views (set as instance variables in controller via ListAuthorization concern)

**Checkpoint**: User Story 2 complete — editors have full item/section editing capabilities. Owner-only controls are hidden from editors.

---

## Phase 5: User Story 8 — Shared Lists in Sidebar and Overview (Priority: P2)

**Goal**: Shared lists appear in the sidebar under "Shared with me" and on the overview page with visual distinction (owner avatar, sharing badge).

**Independent Test**: Share a list with a user, verify it appears in their sidebar under "Shared with me" and on the overview page with the owner's name/avatar.

### Implementation for User Story 8

- [x] T035 [US8] Update TodoListsController#index in app/controllers/todo_lists_controller.rb (load @shared_lists = Current.user.shared_lists.includes(:user, :list_collaborators).recently_updated alongside @todo_lists)
- [x] T036 [US8] Update sidebar partial in app/views/todo_lists/_sidebar.html.erb (add "Shared with me" section below "My Lists" showing @shared_lists or shared_lists local; each shared list shows owner name, dot color, item count; active state for current list works across both sections)
- [x] T037 [US8] Update TodoListsController#show in app/controllers/todo_lists_controller.rb (update @sidebar_lists and add @shared_sidebar_lists; pass both to sidebar partial)
- [x] T038 [US8] Update overview page in app/views/todo_lists/index.html.erb (add "Shared with me" grid section below "My Lists" grid; shared list cards show owner avatar/name and sharing badge)
- [x] T039 [US8] Update _list_card partial in app/views/todo_lists/_list_card.html.erb (accept optional shared: true local; when shared, render owner avatar and "Shared by [name]" label)
- [x] T040 [P] [US8] Create collaborator avatars partial in app/views/shared/_collaborator_avatars.html.erb (renders a stack of up to 3 user avatars with +N overflow count; used on list header for shared lists)
- [x] T041 [US8] Update list header in app/views/todo_lists/show.html.erb (show collaborator avatar stack next to list title when list has collaborators; use _collaborator_avatars partial)
- [x] T042 [US8] Add shared list styles to app/assets/stylesheets/collaboration.css (shared badge, owner avatar on cards, collaborator avatar stack, "Shared with me" sidebar section styling)

**Checkpoint**: User Story 8 complete — shared lists are clearly navigable and visually distinct in sidebar and overview.

---

## Phase 6: User Story 3 — Assign Collaborators to Items (Priority: P2)

**Goal**: Editors can assign one or more collaborators to an item from the list's collaborator pool.

**Independent Test**: Open a shared list item, assign two collaborators from the picker, verify their avatars appear on the item in both list and detail views.

### Implementation for User Story 3

- [x] T043 [US3] Create ItemAssigneesController in app/controllers/item_assignees_controller.rb (include ListAuthorization; authorize_editor! for create/destroy; create adds user from collaborator pool to item — validate user_id is in todo_list.all_members, reject with 404 if not a list member; destroy removes assignee; respond with turbo_stream)
- [x] T044 [US3] Add item_assignees routes nested under todo_items in config/routes.rb (resources :item_assignees, path: "assignees", only: [:create, :destroy])
- [x] T045 [US3] Update assignment picker on item detail view in app/views/todo_items/show.html.erb (replace single assigned_to with multi-select showing all list members via todo_list.all_members; render assigned avatars; each assignee has a remove button)
- [x] T046 [US3] Update _todo_item.html.erb in app/views/todo_lists/_todo_item.html.erb (show assignee avatar stack instead of single assigned_to avatar; use item.assignees eager-loaded)
- [x] T047 [US3] Update _todo_item_completed.html.erb in app/views/todo_lists/_todo_item_completed.html.erb (same assignee avatar stack update)
- [x] T048 [US3] Eager-load assignees in TodoItemsController and TodoListsController (add :item_assignees and assignees to includes/preloader calls to prevent N+1)

**Checkpoint**: User Story 3 complete — multiple collaborators can be assigned to items with avatar display.

---

## Phase 7: User Story 4 — Notify Collaborators on Item Completion (Priority: P2)

**Goal**: When an item is marked done, email notifications are sent to all users on the item's notify list.

**Independent Test**: Add two collaborators to an item's notify list, mark it done, verify both receive completion emails.

### Implementation for User Story 4

- [x] T049 [P] [US4] Add item_completed_email action to CollaborationMailer in app/mailers/collaboration_mailer.rb (accepts todo_item, completed_by user, recipient user; includes item name, list name, completer name)
- [x] T050 [P] [US4] Create completion email views in app/views/collaboration_mailer/item_completed_email.html.erb and app/views/collaboration_mailer/item_completed_email.text.erb
- [x] T051 [US4] Add after_save callback to TodoItem model in app/models/todo_item.rb (when completed changes from false to true, iterate notify_people and send CollaborationMailer.item_completed_email.deliver_later for each; pass Current.user as completer)
- [x] T052 [US4] Update notify people picker on item detail view in app/views/todo_items/show.html.erb (show all list members in picker via todo_list.all_members instead of only Current.user; allow editors to add/remove any collaborator)
- [x] T053 [US4] Update NotifyPeopleController in app/controllers/notify_people_controller.rb (allow creating notify_people records for any collaborator on the list, not just Current.user; validate user_id is in todo_list.all_members, reject with 404 if not a list member per constitution cross-resource FK validation)

**Checkpoint**: User Story 4 complete — completion emails are sent to all users on the notify list.

---

## Phase 8: User Story 5 — Comment and Reply on Items (Priority: P2)

**Goal**: All collaborators (editors and viewers) can post comments and replies on shared list items.

**Independent Test**: Have a viewer and an editor both post comments and replies on the same item, verify all comments are visible to all collaborators.

### Implementation for User Story 5

- [x] T054 [US5] Verify CommentsController authorization allows both editors and viewers to create comments (already handled in T015 — authorize_list_access! not authorize_editor!)
- [x] T055 [US5] Update comment display on item detail to show collaborator avatars in app/views/todo_items/show.html.erb (comments already show user name; ensure avatar/initials render correctly for all collaborators including those from other lists)
- [x] T056 [US5] Verify comment author-only edit/delete still works correctly (existing logic: only comment.user can update/destroy; this is unchanged)

**Checkpoint**: User Story 5 complete — comments work for all collaborators. Minimal changes needed since comment system already exists.

---

## Phase 9: User Story 6 — View-Only Collaboration (Priority: P3)

**Goal**: Viewer-role collaborators can browse all list content and comment but cannot modify any item properties, create/delete items, or manage sections.

**Independent Test**: Invite a user as viewer, verify they can view items, post comments, but cannot change status, priority, notes, tags, due dates, checklist, or create/delete items.

### Implementation for User Story 6

- [x] T057 [US6] Create viewer-specific item detail variant or conditional in app/views/todo_items/show.html.erb (disable/hide: status buttons, priority picker, due date picker, tag add/remove, checklist add/toggle/delete, note editor, file upload, assignment picker, notify picker; keep enabled: comments section, view-only display of all fields)
- [x] T058 [US6] Update inline item creation UI to not render for viewers in app/views/todo_lists/show.html.erb (hide Add Item button, Add Section button, inline input templates for viewers)
- [x] T059 [US6] Update _todo_item.html.erb and _section.html.erb to hide interactive controls for viewers (hide: checkbox toggle, drag handle, context menu; keep: item link for navigation to detail view)
- [x] T060 [US6] Verify server-side authorization rejects viewer attempts to modify (all authorize_editor! before_actions from Phase 2 should already block this; this task is verification and edge case testing)

**Checkpoint**: User Story 6 complete — viewers have a fully read-only experience with commenting ability.

---

## Phase 10: User Story 7 — Manage and Remove Collaborators (Priority: P3)

**Goal**: Owner can change collaborator roles, remove collaborators (preserving their history), and collaborators can voluntarily leave.

**Independent Test**: Change a collaborator from editor to viewer (verify permissions change), remove them (verify access revoked but comments remain), and test voluntary leave.

### Implementation for User Story 7

- [x] T061 [US7] Create ListCollaboratorsController in app/controllers/list_collaborators_controller.rb (include ListAuthorization; authorize_owner! for index/update/destroy; index: render collaboration panel; update: change role; destroy: remove collaborator; leave: collaborator removes themselves — authorize_list_access! only)
- [x] T062 [US7] Add collaborator management routes to config/routes.rb (nested under todo_lists: resources :collaborators controller list_collaborators only [:index, :update, :destroy]; delete "leave" action)
- [x] T063 [US7] Update collaboration panel partial in app/views/todo_lists/_collaboration_panel.html.erb (add role change dropdown per collaborator — standard `<select>` with editor/viewer options; add remove button per collaborator; add "Leave list" button visible only to non-owner collaborators)
- [x] T064 [US7] Add Turbo Stream responses for collaborator management in ListCollaboratorsController (update: broadcast role change; destroy: broadcast collaborator removal, redirect removed user away from list)
- [x] T065 [US7] Verify historical data preservation — confirm comments and item_assignees records from removed users are retained with correct user attribution (comments.user_id FK does not cascade delete; item_assignees cleaned up only via dependent :destroy on list_collaborator removal is NOT cascaded to item_assignees — verify this)

**Checkpoint**: User Story 7 complete — full collaborator lifecycle management.

---

## Phase 11: Real-Time Broadcasting (Cross-Cutting)

**Purpose**: All collaborators see changes live without page refresh via Turbo Streams over ActionCable.

- [x] T066 Add turbo_stream_from subscription to list detail view in app/views/todo_lists/show.html.erb (add `turbo_stream_from @todo_list, :updates` at top of show-main div; only render for authenticated users with list access)
- [x] T067 Add turbo_stream_from subscription to item detail view in app/views/todo_items/show.html.erb (add `turbo_stream_from @todo_item, :updates` for live comment/field updates)
- [x] T068 Add broadcast callbacks to TodoItem model in app/models/todo_item.rb (after_create_commit: broadcast_append_to [todo_list, :updates]; after_update_commit: broadcast_replace_to [todo_list, :updates]; after_destroy_commit: broadcast_remove_to [todo_list, :updates])
- [x] T069 Add broadcast callbacks to Comment model in app/models/comment.rb (after_create_commit: broadcast_append_to [todo_item, :updates]; after_update_commit: broadcast_replace_to; after_destroy_commit: broadcast_remove_to)
- [x] T070 Add broadcast callbacks to TodoSection model in app/models/todo_section.rb (after_create_commit: broadcast_append_to; after_update_commit: broadcast_replace_to; after_destroy_commit: broadcast_remove_to)
- [x] T071 Add broadcast callbacks to ChecklistItem model in app/models/checklist_item.rb (after_update_commit: broadcast_replace_to [todo_item, :updates] for live checklist progress)
- [x] T072 Add broadcast for item_assignees and notify_people changes (after_create_commit and after_destroy_commit on ItemAssignee and NotifyPerson models to broadcast updates to item detail view)
- [x] T073 Verify ActionCable connection authentication in app/channels/application_cable/connection.rb (already authenticates via session cookie — confirm it works with the existing implementation)
- [x] T073a Add broadcast for list deletion to collaborators in app/models/todo_list.rb (before_destroy callback: broadcast_remove_to [self, :updates] so online collaborators see the list disappear from their sidebar; consider broadcasting a Turbo Stream that redirects collaborators to the overview page)

**Checkpoint**: Real-time broadcasting operational — changes from one collaborator appear live on other collaborators' screens.

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Design file updates, security hardening, final cleanup

- [x] T074 [P] Update .pen design files with collaboration UI screens (collaboration panel, shared list sidebar, collaborator avatars on list header and items, viewer-mode item detail, invitation email) — use pencil MCP tools to add new screens to designs/todo-list-item-screens.pen
- [x] T075 [P] Add collaboration link tag to stylesheet in app/views/layouts/app.html.erb if not already done
- [x] T076 Security audit: verify all controllers return 404 (not 403) for unauthorized access per constitution
- [x] T077 Security audit: verify parameter injection is impossible (strong params exclude user_id, role escalation blocked server-side, cross-list assignment prevented)
- [x] T078 Verify eager loading across all updated controllers to prevent N+1 queries (list_collaborators, item_assignees, notify_people, comments.user)
- [x] T079 Run bin/rubocop and fix any offenses in new/modified files
- [x] T080 Run bin/brakeman --no-pager and resolve any warnings
- [x] T081 Run bin/rails test and bin/rails test:system to ensure no regressions
- [x] T082 Update spec.md status from Draft to Complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (migrations must run first) — BLOCKS all user stories
- **Phase 3 (US1 — Invite)**: Depends on Phase 2
- **Phase 4 (US2 — Editor)**: Depends on Phase 2 (can parallel with Phase 3)
- **Phase 5 (US8 — Sidebar)**: Depends on Phase 2 (can parallel with Phase 3/4)
- **Phase 6 (US3 — Assign)**: Depends on Phase 2
- **Phase 7 (US4 — Notify)**: Depends on Phase 2
- **Phase 8 (US5 — Comments)**: Depends on Phase 2 (mostly verification)
- **Phase 9 (US6 — Viewer)**: Depends on Phase 4 (editor controls must exist to conditionally hide)
- **Phase 10 (US7 — Manage)**: Depends on Phase 3 (collaboration panel must exist)
- **Phase 11 (Broadcasting)**: Depends on all user story phases being functional
- **Phase 12 (Polish)**: Depends on all prior phases

### User Story Dependencies

- **US1 (Invite)**: No story dependencies — can start after Foundational
- **US2 (Editor)**: No story dependencies — can parallel with US1
- **US8 (Sidebar)**: No story dependencies — can parallel with US1/US2
- **US3 (Assign)**: No story dependencies — can parallel with US1/US2
- **US4 (Notify)**: No story dependencies — can parallel with US1/US2
- **US5 (Comments)**: No story dependencies — mostly verification
- **US6 (Viewer)**: Depends on US2 (editor controls must exist to hide for viewer)
- **US7 (Manage)**: Depends on US1 (collaboration panel must exist to add management UI)

### Within Each User Story

- Models/migrations before controllers
- Controllers before views
- Mailers before controllers that send emails
- Core implementation before integration

### Parallel Opportunities

- T005, T006, T007 (Phase 2 models) can all run in parallel
- T012–T019 (Phase 2 authorization) can partially overlap — different controller files
- T020, T021 (Phase 3 mailer) can parallel with T022 (routes)
- US1, US2, US8, US3, US4, US5 can all start in parallel after Phase 2
- T049, T050 (Phase 7 mailer) can parallel
- T074, T075 (Phase 12 design/styles) can parallel

---

## Parallel Example: After Phase 2 Completion

```
# These story phases can all launch in parallel after Foundational completes:

Stream A (P1 — Core):
  Phase 3: US1 — Invite a Collaborator
  Phase 4: US2 — Editor Collaboration

Stream B (P2 — Enhancement):
  Phase 5: US8 — Shared Lists in Sidebar
  Phase 6: US3 — Assign Collaborators

Stream C (P2 — Communication):
  Phase 7: US4 — Notify on Completion
  Phase 8: US5 — Comments (verification only)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (migrations)
2. Complete Phase 2: Foundational (models, authorization)
3. Complete Phase 3: US1 — Invite Collaborator
4. Complete Phase 4: US2 — Editor Collaboration
5. **STOP and VALIDATE**: Two users can share a list and edit items together
6. Deploy/demo — core collaboration works

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 + US2 → Core collaboration works (MVP!)
3. US8 → Shared lists navigable in sidebar/overview
4. US3 + US4 → Assignment and completion notifications
5. US5 → Comments verified for multi-user
6. US6 + US7 → Viewer role and collaborator management
7. Broadcasting → Real-time updates across all features
8. Polish → Design files, security audit, CI green

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps each task to its user story for traceability
- Each user story is independently completable and testable after Phase 2
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The existing comment system requires minimal changes — authorization is the main addition
- The `assigned_to_user_id` → `item_assignees` migration requires data migration — test with existing data
- ActionCable connection auth is already implemented — no new infrastructure needed for WebSocket broadcasting

## Completion Summary

**Status**: All tasks complete | **Date**: 2026-03-23

### Test Coverage Added (not in original task list)

99 new tests across 8 test files:

| File | Tests | Coverage |
|------|-------|---------|
| `test/models/list_collaborator_test.rb` | 8 | Validations, associations, owner guard |
| `test/models/list_invitation_test.rb` | 22 | Token generation, accept!, scopes, expiry, validations |
| `test/models/item_assignee_test.rb` | 4 | Associations, uniqueness |
| `test/models/todo_list_collaboration_test.rb` | 10 | role_for, all_members, limit, cascade delete |
| `test/controllers/list_invitations_controller_test.rb` | 14 | Create, accept, destroy, resend, limit, auth |
| `test/controllers/list_collaborators_controller_test.rb` | 11 | CRUD, role changes, leave, comment preservation |
| `test/controllers/item_assignees_controller_test.rb` | 7 | Create/destroy, role auth, member validation |
| `test/controllers/collaboration_authorization_test.rb` | 24 | Cross-cutting editor/viewer/outsider access |

**Full suite**: 400 unit/integration + 23 system = 423 tests, 0 failures

### Issues Found During Implementation

1. Custom web component inputs' shadow DOM doesn't submit form values → replaced with plain `<input>`
2. `deliver_later` needs `:async` adapter in dev → added to `development.rb`
3. `broadcast_replace_to` fails when partials use controller helpers → switched to `broadcast_refresh_to`
4. Duplicate Stimulus controller on panel → removed from partial, kept on parent
5. Brakeman flags `:role` as mass assignment → extract and validate manually
6. `after_registration_url` was dead code → simplified redirect logic
7. `invitation_params` didn't default role → defaults to "editor" when omitted

### Deviations from Original Plan

- **No custom ActionCable channel**: Plan originally listed `todo_list_channel.rb`. Research decided `Turbo::StreamsChannel` with signed stream names is sufficient. No custom channel was created.
- **No `todo_list_channel_controller.js`**: `turbo_stream_from` handles ActionCable subscriptions automatically — no Stimulus controller needed.
- **`broadcast_refresh_to` instead of `broadcast_replace_to`**: Plan assumed partial-based broadcasting. Implementation discovered controller helpers aren't available in broadcast context. `broadcast_refresh_to` (Turbo 8 morph refresh) was used instead.
- **`deliver_now` → `deliver_later`**: Initially switched to `deliver_now` for debugging, then reverted to `deliver_later` with async adapter per Copilot review.
- **Test files added**: Original task generation excluded tests. 99 tests were added in a follow-up pass covering models, controllers, and cross-cutting authorization.
