# Feature Specification: List Collaboration

**Feature Branch**: `005-list-collaboration`
**Created**: 2026-03-23
**Status**: Implementation Complete (with learnings encoded)
**Input**: User description: "Add collaboration support for TODO Lists — invite collaborators, assign items, manage permissions, comment, and notify on completion."

## Design Decision: List-Level Invitations (Not Workspaces)

After analyzing the existing application architecture and UI designs, the recommended approach is **direct list-level invitations** rather than workspaces or organizations. Here's why:

- **Simplicity**: The app is a personal TODO tool. Workspaces add organizational overhead (workspace settings, workspace-level roles, workspace billing, workspace switching) that doesn't match the product's lightweight feel.
- **Granularity**: Users want to share specific lists, not all their lists. A workspace model would either over-share (all lists visible) or require the same per-list permissions anyway.
- **Existing patterns**: The UI already shows assigned users and notify-on-complete users on items — this naturally extends to "people who have access to this list."
- **Progressive complexity**: List-level sharing can later evolve into workspaces if needed, but starting with workspaces and scaling down is harder.

**How it works**: A list owner invites collaborators by email. Each collaborator gets a role on that specific list (editor or viewer). Shared lists appear in the collaborator's sidebar alongside their own lists, clearly distinguished. All existing item features (assign, notify, comment, tags, etc.) work with the pool of collaborators on that list.

## Clarifications

### Session 2026-03-23

- Q: How does a collaborator accept an invitation? → A: Link-based accept — invitee clicks a unique token link in the invitation email to accept. If not yet registered, the link leads to sign-up and auto-accepts after registration.
- Q: How are notifications delivered (completion, invitations)? → A: Email-only for this feature. No in-app notification system will be built now. A full in-app notification subsystem (bell icon, inbox, read/unread) is planned as a future feature.
- Q: Is there a maximum number of collaborators per list? → A: 25 collaborators per list (excluding the owner).
- Q: Should collaborators see changes in real-time without refreshing? → A: Yes — full real-time broadcasting via WebSockets so all collaborators see item changes, new comments, status updates, etc. live.
- Q: Can editors manage sections (create, rename, reorder, archive) on shared lists? → A: Yes — editors have full section management, same as items.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Invite a Collaborator to a List (Priority: P1)

A list owner wants to share their TODO list with a colleague so they can work on it together. The owner opens the list, accesses a sharing/collaboration panel, enters the collaborator's email address, selects a role (editor or viewer), and sends the invitation. The collaborator receives an email with a unique invitation link. Clicking the link accepts the invitation and the shared list appears in their sidebar. If the recipient doesn't have an account, the link leads to sign-up; the invitation auto-accepts once registration is complete.

**Why this priority**: Without the ability to invite people, no other collaboration feature works. This is the foundation.

**Independent Test**: Can be fully tested by having one user invite another by email and verifying the invited user sees the list in their sidebar.

**Acceptance Scenarios**:

1. **Given** a user owns a TODO list, **When** they enter a valid email and select "Editor" role and send the invitation, **Then** the invitation is recorded and the collaborator receives an email with a unique invitation link.
2. **Given** a registered user receives an invitation email, **When** they click the invitation link, **Then** the invitation is accepted and the shared list appears in their sidebar under a "Shared with me" section.
3. **Given** an unregistered user receives an invitation email, **When** they click the link and complete sign-up, **Then** the invitation auto-accepts and the shared list appears in their sidebar.
4. **Given** a user has already invited someone to a list, **When** they try to invite the same email again, **Then** the system informs them that person is already a collaborator.
5. **Given** a user is viewing a list they own, **When** they open the collaboration panel, **Then** they see a list of current collaborators with their roles, pending invitations, and an option to invite more.

---

### User Story 2 - Collaborate on Items as an Editor (Priority: P1)

An editor-role collaborator opens a shared list and works on items just like the owner — they can create items, change status, set priority, edit notes, manage tags, set due dates, and manage checklist items. The only things they cannot do are delete the list itself or manage other collaborators' roles.

**Why this priority**: Editing is the core value of collaboration. Without it, sharing a list is just read-only, which severely limits usefulness.

**Independent Test**: Can be tested by inviting a user as an editor and verifying they can create, edit, and complete items on the shared list.

**Acceptance Scenarios**:

1. **Given** a user has editor access to a shared list, **When** they create a new item, **Then** the item appears in the list and is visible to all collaborators.
2. **Given** a user has editor access, **When** they change an item's status, priority, notes, tags, due date, or checklist, **Then** the changes are saved and visible to all collaborators.
3. **Given** a user has editor access, **When** they attempt to delete the list or manage collaborator roles, **Then** those actions are not available to them.

---

### User Story 3 - Assign Collaborators to Items (Priority: P2)

When working on a shared list, any editor can assign one or more collaborators to a specific item. The assignment picker shows all collaborators on that list (including the owner). Assigning someone signals who is responsible for that item.

**Why this priority**: Assignment is the primary way teams coordinate who does what. It's the most requested collaboration action after basic sharing.

**Independent Test**: Can be tested by opening a shared list item and selecting collaborators from the assignment picker, verifying their avatars appear on the item.

**Acceptance Scenarios**:

1. **Given** a shared list with multiple collaborators, **When** an editor opens the "Assigned to" picker on an item, **Then** they see all collaborators on that list as options.
2. **Given** an item with no assignees, **When** an editor assigns two collaborators, **Then** both users' avatars appear on the item in the list view and detail view.
3. **Given** an item assigned to a collaborator, **When** that collaborator is later removed from the list, **Then** the assignment is preserved as a historical record but the removed user can no longer access the list.

---

### User Story 4 - Notify Collaborators on Item Completion (Priority: P2)

Editors can add collaborators to the "Notify on Complete" list for any item. When the item's status changes to "Done" (or is marked complete), all users on the notify list receive an email notification informing them which item was completed, on which list, and by whom.

**Why this priority**: Completion notifications close the collaboration loop — people need to know when work they depend on is finished.

**Independent Test**: Can be tested by adding a collaborator to the notify list, marking the item done, and verifying the notification is delivered.

**Acceptance Scenarios**:

1. **Given** a shared item with two users on the notify list, **When** any editor marks the item as done, **Then** both users receive an email notification.
2. **Given** an item with no one on the notify list, **When** it is marked done, **Then** no notifications are sent.
3. **Given** a user is on the notify list, **When** the item is marked done and then un-done and marked done again, **Then** the user receives a notification each time it is marked done.

---

### User Story 5 - Comment and Reply on Items (Priority: P2)

All collaborators (both editors and viewers) can leave comments on any item in a shared list. Comments support one level of threaded replies. Users can edit and delete their own comments. Comment authors are identified by name and avatar.

**Why this priority**: Comments enable asynchronous communication about specific items without needing an external tool.

**Independent Test**: Can be tested by having multiple collaborators post comments and replies on a shared item, verifying all see each other's comments.

**Acceptance Scenarios**:

1. **Given** a shared list item, **When** a viewer posts a comment, **Then** the comment appears with their name and avatar and is visible to all collaborators.
2. **Given** an existing comment, **When** another collaborator replies, **Then** the reply appears nested under the original comment.
3. **Given** a user's own comment, **When** they edit it, **Then** the comment shows an "edited" indicator and the updated text.
4. **Given** a user's own comment, **When** they delete it, **Then** the comment and its replies are removed.

---

### User Story 6 - View-Only Collaboration (Priority: P3)

A viewer-role collaborator can see all items, their status, notes, attachments, and checklist progress. They can leave comments (and replies) but cannot modify item properties (status, priority, tags, due date, notes, assigned users, notify list) or create/delete items.

**Why this priority**: View-only access is essential for stakeholders or managers who need visibility without editing ability, but it's lower priority than editor functionality.

**Independent Test**: Can be tested by inviting a user as a viewer and verifying they can browse and comment but not edit any item properties.

**Acceptance Scenarios**:

1. **Given** a user has viewer access to a shared list, **When** they open an item, **Then** they see all item details but editing controls are disabled or hidden.
2. **Given** a viewer, **When** they attempt to change an item's status or priority, **Then** the system does not allow the change.
3. **Given** a viewer, **When** they post a comment on an item, **Then** the comment is saved and visible to all collaborators.

---

### User Story 7 - Manage and Remove Collaborators (Priority: P3)

The list owner can view all collaborators, change their roles (editor ↔ viewer), and remove collaborators. When a collaborator is removed, they lose access to the list immediately, but their past interactions (comments, assignment history) are preserved and attributed to them.

**Why this priority**: Management and removal are necessary for security and control but are less frequently used than the core collaboration actions.

**Independent Test**: Can be tested by changing a collaborator's role and verifying their permissions change, then removing them and verifying they can no longer access the list while their comments remain.

**Acceptance Scenarios**:

1. **Given** a list with an editor collaborator, **When** the owner changes their role to viewer, **Then** the collaborator can no longer edit items but can still view and comment.
2. **Given** a list with a collaborator, **When** the owner removes them, **Then** the collaborator no longer sees the list in their sidebar.
3. **Given** a removed collaborator who had posted comments, **When** any remaining collaborator views those comments, **Then** the comments still show the removed user's name and content.
4. **Given** a collaborator, **When** they choose to leave a shared list voluntarily, **Then** they are removed and their past interactions are preserved.

---

### User Story 8 - Shared Lists in Sidebar and Overview (Priority: P2)

Collaborators see shared lists in their sidebar and on the "My Lists" overview page, clearly distinguished from lists they own. Shared lists show the owner's name and a sharing indicator. The sidebar groups lists into "My Lists" and "Shared with me" sections.

**Why this priority**: Without clear navigation to shared lists, collaborators can't find them. This is essential for the feature to be usable.

**Independent Test**: Can be tested by sharing a list with a user and verifying it appears in the correct section of their sidebar and overview page.

**Acceptance Scenarios**:

1. **Given** a user has been invited to two lists by different owners, **When** they view their sidebar, **Then** they see a "Shared with me" section listing both lists with owner names.
2. **Given** a user owns three lists and is a collaborator on two, **When** they view the overview page, **Then** their own lists and shared lists are visually distinguished (e.g., shared lists show the owner's avatar and a sharing badge).
3. **Given** a shared list, **When** a collaborator opens it, **Then** the list header shows a collaboration indicator (e.g., avatars of collaborators).

---

### Edge Cases

- What happens when the list owner deletes a list that has collaborators? All collaborators lose access and the list is removed from their sidebars. Collaborators could optionally be notified.
- What happens when a collaborator tries to access a list they've been removed from via a direct URL? They see a "list not found or access denied" message.
- What happens if the owner's account is deleted? Shared lists are removed along with the owner's account. Collaborators lose access.
- What happens when two editors edit the same item simultaneously? The last save wins; Turbo Streams ensure near-real-time updates so collaborators see changes as they happen.
- What happens when an invitation email bounces or the recipient never signs up? The pending invitation remains until the owner cancels it or it expires (30 days).
- What if a user is invited to a list but they are already the owner? The system rejects the invitation with a clear message.
- Can a list have zero editors (owner removes themselves)? No — the owner always retains full control and cannot remove themselves. Ownership transfer is out of scope for this feature.
- What happens when a list already has 25 collaborators and the owner tries to invite another? The system displays a message that the collaborator limit has been reached.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow a list owner to invite collaborators by email address with a specified role (editor or viewer), up to a maximum of 25 collaborators per list (excluding the owner).
- **FR-002**: System MUST support two collaborator roles: **editor** (can create, read, update, and complete items and their properties) and **viewer** (can read items and post comments only).
- **FR-003**: System MUST send an email notification to invited collaborators informing them of the shared list.
- **FR-004**: System MUST handle invitations to non-registered emails by creating a pending invitation that activates when the user signs up with that email.
- **FR-005**: System MUST display shared lists in the collaborator's sidebar under a distinct "Shared with me" section, separate from their own lists.
- **FR-006**: System MUST display shared lists on the overview page with a visual indicator (owner's avatar, sharing badge) distinguishing them from owned lists.
- **FR-007**: System MUST allow editors to create, update, complete, archive, and reorder items on shared lists, as well as create, rename, reorder, and archive sections.
- **FR-008**: System MUST prevent viewers from modifying item properties (status, priority, tags, due date, notes, assigned users, notify list, checklist items), creating or deleting items, and managing sections.
- **FR-009**: System MUST allow both editors and viewers to post comments and replies on shared list items.
- **FR-010**: System MUST allow editors to assign any collaborator (including the owner) to an item from the collaborator pool.
- **FR-011**: System MUST allow editors to add any collaborator to an item's "Notify on Complete" list.
- **FR-012**: System MUST send email notifications to all users on an item's notify list when the item is marked as done, including the item name, list name, and who completed it.
- **FR-013**: System MUST allow the list owner to change a collaborator's role (editor ↔ viewer) at any time.
- **FR-014**: System MUST allow the list owner to remove a collaborator, immediately revoking access while preserving their historical interactions (comments, assignment records).
- **FR-015**: System MUST allow a collaborator to voluntarily leave a shared list.
- **FR-016**: System MUST show a collaboration indicator (e.g., collaborator avatars) on the list header when viewing a shared list.
- **FR-017**: System MUST prevent collaborators from deleting the list, managing other collaborators' roles, or transferring ownership.
- **FR-018**: System MUST expire pending invitations after 30 days if not accepted.
- **FR-019**: System MUST allow the owner to cancel a pending invitation before it is accepted.
- **FR-020**: System MUST enforce authorization on all actions — a user without access to a list cannot view, edit, or interact with it or its items in any way.
- **FR-021**: System MUST broadcast changes in real-time to all collaborators currently viewing the same list or item, including item creates/updates/deletes, status changes, comments, and assignment changes.

### Key Entities

- **List Collaboration (Membership)** *(model: `ListCollaborator`)*: Represents a user's access to a specific TODO list. Key attributes: the collaborator (user), the list, their role (editor/viewer), and when they joined. The list owner is implicitly the highest-privilege member and is not stored as a collaboration record.
- **List Invitation**: Represents a pending invitation to collaborate on a list. Key attributes: the inviter (owner), the invited email, the intended role, a unique token (used in the email acceptance link), expiration date (30 days), and status (pending/accepted/expired/cancelled). Clicking the token link accepts the invitation and converts it to a List Collaboration. For unregistered recipients, the token remains valid through sign-up.
- **Comment** *(existing entity, extended)*: Already exists with user attribution. No structural changes needed — collaborators simply gain the ability to comment. Comments from removed collaborators are preserved with their original user attribution.
- **Notification** *(future feature — out of scope)*: A full in-app notification system (bell icon, inbox, read/unread) is planned for a future feature. For this feature, all notifications are delivered via email only. No Notification entity is created now.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A list owner can invite a collaborator and that person can access the shared list within 30 seconds of accepting.
- **SC-002**: 95% of users can successfully invite a collaborator on their first attempt without confusion.
- **SC-003**: Editors on a shared list can perform all item actions (create, edit, complete, assign, tag) with no perceptible difference from working on their own list.
- **SC-004**: Viewers can browse all list content and comment but encounter zero paths to accidentally modify item data.
- **SC-005**: Removing a collaborator immediately revokes all access — the removed user cannot see or interact with the list within 5 seconds of removal.
- **SC-006**: 100% of comments and assignment history from removed collaborators remain visible and attributed after removal.
- **SC-007**: Shared lists are clearly distinguishable from owned lists in the sidebar and overview — users can identify which lists are shared within 2 seconds.
- **SC-008**: Completion email notifications are delivered to all users on the notify list within 60 seconds of an item being marked done.
- **SC-009**: Changes made by one collaborator appear on other collaborators' screens within 2 seconds without requiring a page refresh.

## Assumptions

- **Email delivery**: The application can send transactional emails for invitations and notifications (existing email verification flow confirms this capability).
- **Single owner model**: Each list has exactly one owner. Ownership transfer is out of scope for this feature and can be added later.
- **No workspace/organization layer**: Collaboration is purely at the list level. There is no concept of teams, groups, or organizations.
- **Existing user pool for assignment**: The "Assigned to" and "Notify on Complete" pickers on items will show collaborators on that list, not all users in the system.
- **Real-time updates via WebSocket broadcasting**: Changes made by any collaborator (item creates, updates, completions, comments, etc.) are broadcast in real-time to all other collaborators currently viewing the same list or item. This requires WebSocket infrastructure (e.g., ActionCable) beyond the existing single-session Turbo Streams.
- **Email-only notifications**: All notifications (completion alerts, invitation emails) are delivered via email. There is no in-app notification UI for this feature. A full in-app notification subsystem (bell icon, notification inbox, read/unread tracking) is planned as a separate future feature.
- **No per-field permissions**: Editor role grants access to all editable fields on an item (status, priority, tags, due date, notes, checklist, assignments, notify list). There is no granular per-field permission model. This was an explicit design decision — the simplicity of two roles (editor/viewer) covers the vast majority of collaboration needs without the complexity of field-level access control.

## Implementation Learnings

Captured during implementation and code review of feature 005:

- **`wa-input` does not submit in forms**: Shadow DOM prevents `wa-input` name/value from reaching `FormData`. Use plain `<input>` elements for form fields that must submit data. This was discovered when invitation emails were not sending — the email param was nil.
- **`deliver_later` requires async adapter in development**: Without `config.active_job.queue_adapter = :async` in `development.rb`, Solid Queue jobs are enqueued but never processed (no worker running). The `:async` adapter processes jobs in a thread pool within the same process.
- **`broadcast_refresh_to` over `broadcast_replace_to`**: Partials that reference controller helper methods (`list_editor?`, `list_owner?`) cannot render inside model broadcast callbacks (no controller context). `broadcast_refresh_to` triggers Turbo 8 morph-based page refresh, avoiding the partial rendering issue entirely.
- **Brakeman flags `:role` in `permit()`**: Even though `role` is validated at the model level, Brakeman treats it as a mass assignment risk. Fix by extracting the param and validating against an allowlist before merging into permitted params.
- **Invitation resend vs. duplicate error**: The unique partial index `(todo_list_id, email) WHERE status='pending'` prevents duplicate pending invitations. Instead of surfacing a DB uniqueness error, check for existing active invitations first and resend the email.
- **Invitation token invalidation**: `generates_token_for :acceptance` keyed on `status` means the token auto-invalidates when the invitation is accepted, cancelled, or expired. No manual token revocation needed.
- **Integration tests use `assert_response :not_found`**: Rails rescues `ActiveRecord::RecordNotFound` in integration tests and returns 404. Do NOT use `assert_raises` — it won't catch the rescued exception.
- **`assigned_to_user_id` → `item_assignees` migration**: The reversible migration copies existing single-assignment data to the join table before dropping the column. All views and controllers referencing `assigned_to` must be updated simultaneously.
- **Stimulus controller scope**: `data-controller` must be on an ancestor of all targets. When the collaboration panel partial declared its own `data-controller="collaboration"`, it created a second instance that shadowed the parent — the toggle button on the header couldn't find the panel target.

## Future Features (Out of Scope)

Features identified during implementation that should be built in future iterations:

1. **In-app notification system** — Bell icon, notification inbox, read/unread tracking. Currently all notifications are email-only. This is the most requested follow-up feature. Should cover: invitation received, item completed, comment mention, role changed, removed from list.
2. **Ownership transfer** — Allow a list owner to transfer ownership to another collaborator. Currently the owner is permanent and cannot be changed.
3. **Notification preferences** — Allow users to opt out of specific email notification types (e.g., completion emails) or set digest frequency (immediate vs. daily summary).
4. **Real-time presence indicators** — Show which collaborators are currently viewing the same list or item (avatar dots, "X is viewing" label).
5. **Workspace/organization layer** — If collaboration usage grows beyond individual list sharing, a workspace model could group lists and provide org-level roles. The current list-level invitation model was chosen for simplicity and can evolve into workspaces later.
6. **Comment mentions (@user)** — Allow mentioning collaborators in comments with `@name` syntax, triggering an email notification to the mentioned user.
7. **Activity feed / audit log** — Track who did what on a shared list (created items, changed status, added comments) with timestamps. Useful for accountability in team settings.
8. **Bulk invitation** — Allow inviting multiple email addresses at once (comma-separated or pasted list) instead of one at a time.
