# Feature Specification: TODO Item Detail Screen

**Feature Branch**: `004-todo-item-detail`
**Created**: 2026-03-22
**Status**: Draft
**Input**: User description: "Flesh out the TODO Item Detail Screen with full feature support: notes, checklist, attachments, comments (with likes and replies), status, priority, due date, assignees, notify on complete, tags, mark complete, and delete."

## Clarifications

### Session 2026-03-22

- Q: Should users be able to edit and delete their own comments? -> A: Yes. Users can edit (showing "(edited)" indicator) and delete their own comments. Deleting a parent comment also removes its replies.
- Q: How do "Mark Complete" and the "Done" status relate? -> A: They are fully synchronized. Setting status to "Done" also marks the item complete; clicking "Mark Complete" sets status to "Done". Unmarking complete reverts status to "To Do".
- Q: How should unsaved note changes be handled? -> A: Auto-save. Note content saves automatically on blur or after a brief delay. No manual save button is needed.
- Q: What rich text editor should be used for Notes? -> A: Lexxy (basecamp/lexxy), the successor to Trix. It integrates with ActionText as a drop-in replacement.
- Q: Should the Notes section require an "Edit" button to enter editing mode? -> A: No. The Notes section is always editable — the Lexxy editor is always visible and active. No view/edit mode toggle needed.
- Q: Should the priority be called "Normal" or "Medium"? -> A: "Medium". The internal enum value is "medium" and the display label is "Medium", matching the design reference.

### Implementation Learnings (2026-03-22)

- **Rails 8.1 validates `before_action only:` action names**: `before_action :callback, only: %i[update destroy]` will raise `AbstractController::ActionNotFound` if `update` is not a defined action on the controller. This was not the case in Rails 7.x. Remove non-existent action names from `only:` filters.
- **Lexxy gem installation**: `gem 'lexxy', '~> 0.1.26.beta'` + `bin/importmap pin lexxy` + `import "lexxy"` in application.js. Replace `import "trix"` and `import "@rails/actiontext"` — Lexxy handles both. Set `config.lexxy.override_action_text_defaults = true` in an initializer.
- **Lexxy CSS**: Add `stylesheet_link_tag` for `lexxy`, `lexxy-editor`, `lexxy-content`, `lexxy-variables` in the layout. Update ActionText content partial from `trix-content` to `lexxy-content` class.
- **Lexxy auto-save pattern**: Listen for `lexxy:change` event in a Stimulus controller, debounce 2 seconds, submit form via `fetch()` with FormData. Save immediately on `disconnect()` to prevent data loss during navigation. Follows Fizzy's `auto_save_controller.js` pattern.
- **TodoItemScoped concern was abandoned**: The Fizzy-style scoped concern approach caused issues in integration tests. Controllers use private `set_todo_list`/`set_todo_item` methods instead (same pattern as the existing TodoItemsController). The concern file remains in `app/controllers/concerns/` but is not included anywhere.
- **Priority rename migration**: Since `priority` is a string column (not a DB enum), renaming "medium" to "normal" is a simple `UPDATE` statement, not a schema change.
- **Comment reply nesting**: Self-referential `parent_id` on Comment with `dependent: :destroy` on the `replies` association handles cascade deletion cleanly. The `nesting_depth_limit` validation checks `parent.parent_id.nil?` to enforce 1-level max.
- **Priority renamed from "normal" to "medium"**: The internal enum value, DB column default, data migration, model constants, and UI labels all use "medium" now. The label displayed is "Medium". This was changed mid-implementation to match the design reference.
- **Notes section uses Edit button toggle, NOT always-editable**: Despite the original spec saying always-editable, the final implementation uses an Edit/Done toggle button matching the `TODO Item Detail` design. Click Edit to show the Lexxy editor, click Done to return to rendered view. Auto-save still works while editing.
- **Status badge in header is always purple (#8B5CF6)**: Regardless of the actual status value, the status badge above the item title always uses purple background and dot, matching the design reference.
- **Lexxy gem JS must be pinned from the gem's asset path, NOT npm**: `bin/importmap pin lexxy` downloads a wrong npm package (a tiny lexer library). The correct approach is `pin "lexxy", to: "lexxy.min.js"` which resolves through Propshaft to the gem's bundled JS (692KB editor). Also requires `pin "@rails/activestorage", to: "activestorage.esm.js"` because Lexxy imports it internally.
- **Lexxy replaces both Trix imports**: Remove `import "trix"` and `import "@rails/actiontext"` from application.js, replace with just `import "lexxy"`. Update the ActionText content partial class from `trix-content` to `lexxy-content`.
- **`display: contents` on button_to form wrappers**: `button_to` generates `<form><button>` which creates block-level form wrappers that break flex layouts. Using `display: contents` on the form makes it invisible to layout, but causes issues when hidden inputs leak into flex containers. For checklist items, switched to `link_to` with `data-turbo-method` to avoid the form wrapper entirely.
- **Cross-item reply security**: Added `parent_belongs_to_same_item` validation on Comment model to prevent creating replies whose parent comment belongs to a different todo_item. Without this, a user could create cross-item data leakage via the parent_id parameter. Found during Copilot code review.
- **N+1 on comment likes**: `comment.liked_by?(Current.user)` uses `exists?` which hits the DB even when `comment_likes` is eager-loaded. Cache the lookup once per comment using the loaded association: `comment.comment_likes.find { |l| l.user_id == Current.user.id }`.
- **Double fetch in show action**: The `before_action :set_todo_item` fetches the item, then `show` re-fetched it with `includes().find()`. Use `ActiveRecord::Associations::Preloader` instead to eager-load onto the already-fetched record.
- **Status selector is a segmented control**: The design uses a gray `#E4E4E7` pill container (border-radius 12px, padding 4px) with buttons inside (border-radius 8px). Not individual bordered buttons.
- **Checklist uses `link_to` with `data-turbo-method` instead of `button_to`**: Avoids form wrapper issues. Toggle uses `data: { turbo_method: :patch }`, delete uses `data: { turbo_method: :delete, turbo_confirm: "..." }`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View and Edit Item Status & Priority (Priority: P1)

A user opens a TODO item's detail screen to view all of its information and change its status or priority. The detail screen is organized into a two-column layout: a left column for the item's content (notes, checklist, attachments, comments) and a right column for metadata and actions (status, priority, assignees, due date, notifications, tags, and action buttons). The top bar shows the parent list name with a back button for navigation.

**Why this priority**: Status and priority are the most fundamental item attributes. Users must be able to view and update these to manage their work. This story also establishes the detail screen layout that all other stories build upon.

**Independent Test**: Can be fully tested by navigating to a TODO item detail page, viewing the status selector and priority options, selecting different values, and verifying the changes persist.

**Acceptance Scenarios**:

1. **Given** a user viewing a TODO list, **When** they click on a TODO item's title, **Then** they are navigated to the item detail screen showing the item's full information in a two-column layout.
2. **Given** a user on the item detail screen, **When** they view the top bar, **Then** they see a back button, the parent list icon and name, and an edit pencil icon.
3. **Given** a user on the item detail screen, **When** they view the item header in the left column, **Then** they see a status badge (colored), a priority badge, the item title, creation date, and section name.
4. **Given** a user viewing the status card in the right column, **When** they see the status selector, **Then** it displays four options: To Do, In Progress, On Hold, and Done, with the current status visually highlighted.
5. **Given** a user viewing the status card, **When** they click a different status option, **Then** the status updates immediately, the header status badge updates to match, and the change is saved. If "Done" is selected, the item is also marked as complete; if changed away from "Done", the item is unmarked as complete.
6. **Given** a user viewing the priority card in the right column, **When** they see the priority options, **Then** it displays five options: Urgent (red dot), High (amber dot), Normal (blue dot), Low (teal dot), and None (gray dot), with the current priority indicated by a checkmark.
7. **Given** a user viewing the priority card, **When** they click a different priority option, **Then** the priority updates immediately, the header priority badge updates to match, and the change is saved.

---

### User Story 2 - Add and Edit Notes (Priority: P1)

A user adds or edits a rich-text note on a TODO item to capture detailed information, context, and planning thoughts. The notes section uses the Lexxy editor (successor to Trix) and is always editable — the editor is always visible and active with no view/edit mode toggle. Notes auto-save on content change.

**Why this priority**: Notes are the primary way users capture detailed context for a TODO item beyond its title. This is essential for items that require planning or have multi-step requirements.

**Independent Test**: Can be fully tested by opening an item detail screen, typing in the always-visible Lexxy editor, and verifying the content auto-saves and renders correctly with formatting.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Notes section, **Then** they see the section header with a "Notes" label and file-text icon, and the Lexxy rich text editor is always visible and ready for input.
2. **Given** a user viewing the Notes section with no existing note, **When** they see the editor, **Then** it shows a placeholder prompt and is immediately editable.
3. **Given** a user typing in the Notes editor, **When** they enter text with formatting (paragraphs, bullet lists, emphasis), **Then** the content auto-saves on change and is persisted without a manual save action.
4. **Given** a user on an item with an existing note, **When** they view the Notes section, **Then** the note content is loaded into the Lexxy editor in a styled card, fully editable.
5. **Given** a user modifying an existing note, **When** they change the content, **Then** the updated content auto-saves and replaces the previous version.

---

### User Story 3 - Manage Checklist Items (Priority: P1)

A user creates and manages a checklist within a TODO item to break down work into smaller, trackable sub-tasks. The checklist shows a progress indicator (e.g., "2/4"), and individual items can be marked as complete or incomplete.

**Why this priority**: Checklists are a core productivity feature that allows users to decompose complex tasks into actionable steps and track progress at a granular level.

**Independent Test**: Can be fully tested by opening an item detail, adding checklist items, checking/unchecking them, and verifying the progress indicator updates.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Checklist section, **Then** they see a section header with a "Checklist" label, list-checks icon, a progress badge showing completion ratio, and an "Add" button.
2. **Given** a user viewing the Checklist section, **When** they click the "Add" button, **Then** an input appears allowing them to type a new checklist item name.
3. **Given** a user adding a checklist item, **When** they submit the item name, **Then** the item appears in the list as an unchecked item and the progress badge denominator increases.
4. **Given** a user viewing a pending checklist item, **When** they click the checkbox, **Then** the item is marked as complete (teal checkmark, text becomes gray/muted) and the progress badge numerator increases.
5. **Given** a user viewing a completed checklist item, **When** they click the checkbox again, **Then** the item reverts to pending (empty checkbox, text returns to normal) and the progress badge numerator decreases.
6. **Given** a user viewing a checklist item, **When** they choose to edit it, **Then** they can modify the item's text.
7. **Given** a user viewing a checklist item, **When** they choose to remove it, **Then** the item is deleted from the checklist and the progress badge updates accordingly.

---

### User Story 4 - Manage Attachments (Priority: P2)

A user uploads, views, and removes file attachments on a TODO item to associate relevant documents, images, and spreadsheets with their work. Attachments display as file cards showing a type-specific icon, file name, and file size.

**Why this priority**: Attachments allow users to keep all relevant materials co-located with the task. This is important but secondary to the core task management features (status, notes, checklist).

**Independent Test**: Can be fully tested by opening an item detail, uploading files of different types, verifying they appear as file cards, and removing an attachment.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Attachments section, **Then** they see a section header with an "Attachments" label, paperclip icon, a count badge showing total attachments, and an "Upload" button.
2. **Given** a user in the Attachments section, **When** they click the "Upload" button, **Then** a file picker dialog opens allowing them to select one or more files.
3. **Given** a user selecting files to upload, **When** the upload completes, **Then** each file appears as a card showing a type-specific icon (image=pink, document=purple, spreadsheet=teal), file name, and file size, and the count badge updates.
4. **Given** a user viewing an attachment card, **When** they choose to remove the attachment, **Then** the file card is removed from the grid and the count badge decreases.
5. **Given** a user viewing an attachment card, **When** they click on it, **Then** the file is downloaded or previewed.

---

### User Story 5 - Manage Comments with Likes and Replies (Priority: P2)

A user adds, edits, and deletes comments on a TODO item to discuss the task, and can like or reply to existing comments. Each comment shows the author's avatar, name, timestamp, and text content. Users can edit their own comments (showing an "(edited)" indicator) or delete them (which also removes any replies). A comment input bar at the bottom allows composing new comments.

**Why this priority**: Comments enable discussion and collaboration context around a task. Likes and replies add engagement. This builds on the single-user stub model from feature 003 but fully implements the commenting interaction patterns.

**Independent Test**: Can be fully tested by opening an item detail, adding a comment, editing it, deleting it, liking an existing comment, replying to a comment, and verifying the comment count updates.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Comments section, **Then** they see a section header with a "Comments" label, message-circle icon, and a count badge showing total comments.
2. **Given** a user viewing the Comments section, **When** comments exist, **Then** each comment displays an avatar, author name, timestamp, comment text, a like button with like count, and a "Reply" link.
3. **Given** a user viewing the comment input bar, **When** they see it, **Then** it shows their avatar, a "Write a comment..." placeholder, and a purple "Send" button with a send icon.
4. **Given** a user typing in the comment input, **When** they click "Send", **Then** the comment is added to the list, the count badge increases, and the input clears.
5. **Given** a user viewing a comment, **When** they click the like (heart) icon, **Then** the like count increments and the heart icon visually indicates the user's like (filled/colored).
6. **Given** a user who has already liked a comment, **When** they click the like icon again, **Then** the like is removed and the count decrements.
7. **Given** a user viewing a comment, **When** they click "Reply", **Then** a reply input appears allowing them to compose a response associated with that comment.
8. **Given** a user submitting a reply, **When** the reply is saved, **Then** it appears nested under the parent comment with the same layout (avatar, name, timestamp, text, like, reply).
9. **Given** a user viewing their own comment, **When** they choose to edit it, **Then** the comment text becomes editable, they can modify and save the changes, and an "(edited)" indicator appears next to the timestamp.
10. **Given** a user viewing their own comment, **When** they choose to delete it, **Then** the comment and all its replies are removed from the list and the count badge decreases accordingly.

---

### User Story 6 - Set Due Date (Priority: P2)

A user sets or changes a due date on a TODO item. The due date card displays the selected date with a countdown indicator showing how many days remain, color-coded by urgency.

**Why this priority**: Due dates are essential for time-sensitive task management and integrate with the existing due date badges on the list view.

**Independent Test**: Can be fully tested by opening an item detail, setting a due date via the date card, verifying the date and countdown display, and changing it.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Due Date card in the right column, **Then** they see a "Due Date" label, the current date (or empty state if unset), a countdown indicator, and an edit pencil icon.
2. **Given** a user with a set due date, **When** the date is in the future, **Then** the countdown shows "X days left" in amber/yellow with a calendar-clock icon.
3. **Given** a user with a set due date, **When** the date has passed, **Then** the countdown shows "X days overdue" in red.
4. **Given** a user viewing the Due Date card, **When** they click the edit icon or the date area, **Then** a date picker opens allowing them to select a new date.
5. **Given** a user selecting a new date, **When** they confirm the selection, **Then** the due date updates with the new date and the countdown recalculates.
6. **Given** a user with a due date set, **When** they want to clear the due date, **Then** they can remove it and the card shows an empty/unset state.

---

### User Story 7 - Manage Assignees (Priority: P2)

A user assigns and removes people from a TODO item. The assignees card shows each assignee's avatar, name, and role, with a remove button. An add button allows assigning additional people.

**Why this priority**: Assignment is important for accountability, even in the current single-user context where users assign to themselves. The data model supports future multi-user expansion.

**Independent Test**: Can be fully tested by opening an item detail, adding an assignee, verifying their avatar/name/role display, and removing them.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Assignees card in the right column, **Then** they see an "Assigned to" label, the current assignee (avatar, name) with a remove (x) button, or an empty state with a user-plus add button.
2. **Given** a user viewing the Assignees card with no assignee, **When** they click the add (user-plus) button, **Then** the current user is assigned to the item.
3. **Given** a user viewing the Assignees card with an assignee, **When** they click the remove (x) icon, **Then** the assignee is removed.
4. **Given** an item with no assignee, **When** the user views the Assignees card, **Then** an empty state is shown with the add button available.

---

### User Story 8 - Manage Notify on Complete List (Priority: P3)

A user adds or removes people to be notified when the TODO item is marked as complete. The notify card shows each person's avatar, name, and role, with a remove button and an add button.

**Why this priority**: Notification on completion is a convenience feature that supports accountability. It's lower priority because it enhances rather than enables core task management.

**Independent Test**: Can be fully tested by opening an item detail, adding a person to the notify list, verifying their display, and removing them.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Notify on Complete card, **Then** they see a "Notify on Complete" label, a list of current people (avatar, name, role), remove (x) buttons, and a bell-plus add button.
2. **Given** a user viewing the Notify card, **When** they click the add (bell-plus) button, **Then** they can add a person to be notified.
3. **Given** a user viewing a person in the notify list, **When** they click the remove (x) icon, **Then** the person is removed from the notify list.
4. **Given** an item being marked as complete, **When** the status changes to done, **Then** the notify list is recorded for future notification delivery (no actual notification sent in this single-user stub).

---

### User Story 9 - Manage Tags (Priority: P3)

A user adds and removes tags on a TODO item to categorize and filter tasks. Tags display as colored pills, and an "Add tag" action allows creating or selecting tags.

**Why this priority**: Tags provide organizational flexibility but are supplementary to the primary task management features.

**Independent Test**: Can be fully tested by opening an item detail, adding tags, verifying they appear as colored pills, and removing them.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Tags card in the right column, **Then** they see a "Tags" label, existing tags displayed as colored pills, and an "Add tag" link with a plus icon.
2. **Given** a user viewing the Tags card, **When** they click "Add tag", **Then** they can select from existing tags or create a new tag.
3. **Given** a user adding a tag, **When** the tag is applied, **Then** it appears as a colored pill in the Tags card.
4. **Given** a user viewing a tag on the item, **When** they choose to remove it, **Then** the tag pill is removed from the item (the tag itself continues to exist for use on other items).

---

### User Story 10 - Mark Complete and Delete Item (Priority: P2)

A user marks a TODO item as complete or deletes it entirely from the item detail screen. A prominent "Mark Complete" button and a "Delete Item" button are displayed in the actions section of the right column.

**Why this priority**: Completing and deleting items are essential lifecycle actions. Completing is the primary success path for any TODO item.

**Independent Test**: Can be fully tested by marking an item complete and verifying the state change, and by deleting an item and verifying it's removed.

**Acceptance Scenarios**:

1. **Given** a user on the item detail screen, **When** they view the Actions section in the right column, **Then** they see a teal "Mark Complete" button with a circle-check icon and a red-outlined "Delete Item" button with a trash icon.
2. **Given** a user viewing an incomplete item, **When** they click "Mark Complete", **Then** the item is marked as complete, the status updates to "Done", and the button visually changes to indicate the completed state.
3. **Given** a user viewing a completed item, **When** they view the "Mark Complete" button, **Then** it reflects the completed state and allows them to unmark (toggle back to incomplete).
4. **Given** a user viewing the "Delete Item" button, **When** they click it, **Then** a confirmation prompt appears asking them to confirm the deletion.
5. **Given** a user confirming deletion, **When** they confirm, **Then** the item is permanently deleted and they are navigated back to the parent TODO list.
6. **Given** a user canceling deletion, **When** they dismiss the confirmation, **Then** no action is taken and they remain on the detail screen.

---

### Edge Cases

- What happens when a user tries to add a checklist item with an empty name? The system rejects it and keeps the input active.
- What happens when a user uploads an attachment that exceeds the maximum file size? The system shows an error message with the maximum allowed size and does not save the file.
- What happens when a user tries to add a duplicate tag to an item? The system prevents duplicate tags on the same item and shows a message that the tag is already applied.
- What happens when a user marks an item as complete that has incomplete checklist items? The item is marked complete regardless — checklist completion does not block item completion.
- What happens when a user edits a note and navigates away? Notes auto-save on blur or after a brief delay, so no data is lost.
- What happens when a user tries to delete the only item in a list? The item is deleted normally and the user returns to the list, which shows its empty state.
- What happens when a comment contains only whitespace? The system rejects it and does not create a comment.
- What happens when a user clicks "Reply" on a reply (nested reply)? Replies are limited to one level of nesting — replying to a reply creates a reply at the same level, not deeper nesting.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display the TODO item detail screen in a two-column layout: left column for content sections (header, notes, checklist, attachments, comments) and right column for metadata and actions (status, priority, assignees, due date, notify on complete, tags, mark complete, delete).
- **FR-002**: System MUST display a top bar with a back button, parent list icon and name, and an edit icon for the list title.
- **FR-003**: System MUST display an item header showing the current status badge (colored), priority badge, item title, creation date, and section name.
- **FR-004**: System MUST allow users to set and change the item status via a segmented selector with four options: To Do (default), In Progress, On Hold, and Done.
- **FR-005**: System MUST allow users to set and change the item priority from five options: Urgent (red), High (amber), Normal (blue), Low (teal), and None (gray), with the selected priority indicated by a checkmark.
- **FR-006**: System MUST allow users to add and edit a rich-text note on an item, supporting formatted text (paragraphs, bullet lists, emphasis). Notes auto-save on blur or after a brief delay.
- **FR-007**: System MUST display notes in a styled card with proper text formatting.
- **FR-008**: System MUST allow users to add, edit, and remove checklist items within a TODO item.
- **FR-009**: System MUST allow users to mark individual checklist items as complete or incomplete.
- **FR-010**: System MUST display a progress indicator on the checklist section showing the completion ratio (e.g., "2/4").
- **FR-011**: System MUST allow users to upload file attachments to a TODO item.
- **FR-012**: System MUST display each attachment as a card showing a type-specific icon, file name, and file size.
- **FR-013**: System MUST allow users to remove attachments from a TODO item.
- **FR-014**: System MUST allow users to add comments to a TODO item via a comment input bar.
- **FR-015**: System MUST display each comment with the author's avatar, name, timestamp, and text content.
- **FR-016**: System MUST display a count badge showing the total number of comments.
- **FR-017**: System MUST allow users to like and unlike comments, with a visible like count per comment.
- **FR-018**: System MUST allow users to reply to comments, with replies displayed nested under the parent comment.
- **FR-019**: System MUST limit reply nesting to one level deep.
- **FR-030**: System MUST allow users to edit their own comments, displaying an "(edited)" indicator next to the timestamp after modification.
- **FR-031**: System MUST allow users to delete their own comments, which also removes all replies to that comment.
- **FR-020**: System MUST allow users to set, change, and clear a due date on an item.
- **FR-021**: System MUST display the due date with a countdown indicator (days remaining or overdue), color-coded by urgency.
- **FR-022**: System MUST allow users to assign and unassign a single person to an item (single-user stub: current user only), displaying the assignee's avatar and name.
- **FR-023**: System MUST allow users to add and remove people from the "Notify on Complete" list, displaying each person's avatar and name.
- **FR-024**: System MUST allow users to add and remove tags on an item, displaying tags as colored pills.
- **FR-025**: System MUST allow users to mark an item as complete via a prominent "Mark Complete" button, which updates the item status to Done. The completed state and "Done" status are fully synchronized: setting status to "Done" via the status selector also marks the item complete, and unmarking complete reverts status to "To Do".
- **FR-026**: System MUST allow users to delete an item after confirmation, navigating back to the parent list upon deletion.
- **FR-027**: System MUST validate that checklist item names are not empty before saving.
- **FR-028**: System MUST validate that comments are not empty or whitespace-only before saving.
- **FR-029**: System MUST prevent duplicate tags from being applied to the same item.

### Key Entities

- **TODO Item**: The central entity with attributes: name, completed status, status (To Do/In Progress/On Hold/Done), priority (Urgent/High/Normal/Low/None), due date, creation date, position, and associations to a list and optionally a section.
- **Note**: Rich-text content associated with a TODO item. One note per item. Supports formatted text including paragraphs, lists, and emphasis.
- **Checklist Item**: A sub-task within a TODO item with attributes: name, completed status, position. Belongs to a TODO item. Many per item.
- **Attachment**: A file associated with a TODO item with attributes: file reference, file name, file size, file type. Belongs to a TODO item. Many per item.
- **Comment**: A text entry on a TODO item with attributes: body text, author, created timestamp, like count. Belongs to a TODO item. Supports one level of replies (parent comment reference).
- **Comment Like**: A record that a user liked a specific comment. One per user per comment.
- **Assignee**: The person assigned to a TODO item via a direct user reference. One per item (single-user stub). The UI presents assignment as a card with avatar and name for visual consistency with the multi-user design, but the data model stores a single `assigned_to` user reference.
- **Notify Person**: A user to be notified when the item is completed. Belongs to a TODO item via user reference. Many per item.
- **Tag**: A categorization label with a name and color. Can be applied to many items. An item can have many tags (many-to-many relationship).

## Assumptions

- The "Normal" priority level corresponds to what the design labels as "Medium" — the user-provided priority names (Urgent, High, Normal, Low, None) take precedence over the design mockup label.
- Notify on Complete functionality currently operates within the single-user stub model established in feature 003. The data model supports future multi-user expansion, but no real notification delivery (email, push) is implemented in this feature.
- Assignees follow the same single-user stub model — users can assign to themselves. The UI and data model support multiple assignees for future multi-user expansion.
- File attachment size limits follow standard web application defaults (reasonable max per file, e.g., 10MB). The exact limit will be determined during implementation.
- Tags use the existing Tag model from feature 003, extended with color support for display as colored pills.
- Marking an item complete does not require all checklist items to be complete — these are independent tracking mechanisms.
- The comment author is always the current logged-in user.
- Rich text notes use ActionText with the Lexxy editor (replacing Trix), as clarified in session 2026-03-22. Lexxy is a drop-in ActionText replacement.
- In the single-user stub, assignee and notify-person displays show the user's name. The "role" labels visible in the design (e.g., "Lead Designer", "PM") are aspirational for multi-user and are not implemented in this feature.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view all item details (status, priority, notes, checklist, attachments, comments, due date, assignees, tags) on a single detail screen within 2 seconds of navigation.
- **SC-002**: Users can change item status or priority with a single click and see the update reflected immediately.
- **SC-003**: Users can add a checklist item, mark it complete, and see the progress indicator update within a single interaction flow.
- **SC-004**: Users can upload an attachment and see it displayed as a file card without leaving the detail screen.
- **SC-005**: Users can add a comment and see it appear in the comments list immediately after submission.
- **SC-006**: Users can complete the full item lifecycle (create → set status/priority → add notes → mark complete) without navigating away from the detail screen.
- **SC-007**: 100% of functional requirements are covered by automated tests.
- **SC-008**: All user-facing actions (status change, priority change, checklist toggle, comment submission) provide immediate visual feedback.

## Deferred Features

- **Comment Reply functionality**: Reply button removed from UI. The data model (parent_id, nesting validation) is implemented. Need to add: reply input form that appears when Reply is clicked, Stimulus controller to toggle reply form, `parent_id` passed in the form submission.
- **Comment Edit functionality**: Edit button removed from UI. The controller `update` action exists with `edited_at` timestamp. Need to add: inline edit form in the comment partial, Stimulus controller to toggle between view/edit mode, form submission to PATCH the comment.
- **Real notification delivery for Notify on Complete**: Currently a single-user stub — data model exists but no actual notifications are sent when an item is marked complete. Need to implement email/push notification delivery.
- **Multi-user assignees**: Currently single-assignment via `assigned_to_user_id` FK. To support multiple assignees, create an `assignments` join table (like `notify_people`). The UI card already shows the pattern.
- **Custom date picker**: Currently uses native HTML date input with `showPicker()`. The design shows a custom popover with quick-pick buttons (Today, Tomorrow, Next Week, No Date) and a calendar grid. Implement as a Stimulus-controlled dropdown.
- **Tag color picker**: Currently uses a basic HTML color input. Could be enhanced with preset color swatches matching the design.
- **Attachment preview/download**: Clicking an attachment card should download or preview the file. Currently file cards are display-only.
