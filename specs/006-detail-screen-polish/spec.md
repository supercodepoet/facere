# Feature Specification: Detail Screen Polish

**Feature Branch**: `006-detail-screen-polish`
**Created**: 2026-03-23
**Status**: Draft
**Input**: Polish TODO List Detail and TODO Item Detail screens to match the visual reference in `todo-list-item-screens.pen`.

## Visual Reference

Source of truth: `designs/todo-list-item-screens.pen`
- **TODO List Detail** (`nGCDe`): Item rows with due date badges, priority dots, assignee avatars, status indicators. Section and item context menus.
- **TODO Item Detail** (`sogSu`): Status/priority pills at top, full notes editor with Save button, assignee picker from collaborator pool, due date with calendar picker, notify-on-complete picker, attachment upload and file cards, comments with threading.
- **Section Context Menu** (`Df59j`): Edit, Move, Copy, New list from group, Archive group, Delete group, Insert a to-do.
- **Item Context Menu** (`9xhXA`): Edit, Move, Copy, Archive, Delete item.
- **Date Picker** (`DVrEg`): Calendar overlay for selecting due dates.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Item Pills and Badges on List View (Priority: P1)

A user viewing a TODO list sees at-a-glance information on each item row: a colored due date badge (showing the date or "Overdue"), a priority indicator dot, and assignee avatar(s). These visual cues match the design reference and allow users to quickly scan item urgency and ownership without opening each item.

**Why this priority**: These pills are the most visible gap between the current implementation and the design. Every user sees the list view first — getting it right is the foundation.

**Independent Test**: Open any list with items that have due dates, priorities, and assignees set. Verify the badges, dots, and avatars display inline on each item row matching the design.

**Acceptance Scenarios**:

1. **Given** an item with a due date in the future, **When** viewing the list, **Then** a colored date badge shows the formatted date (e.g., "Mar 5") with style matching urgency (green for far, yellow for approaching, red for overdue).
2. **Given** an item with priority set (low/medium/high/urgent), **When** viewing the list, **Then** a small colored dot appears indicating priority level, matching the design color scheme.
3. **Given** an item with one or more assignees, **When** viewing the list, **Then** assignee avatar(s) appear on the item row (max 2 shown, +N overflow for more).
4. **Given** an item with status "In Progress", **When** viewing the list, **Then** the checkbox circle shows a colored fill or indicator matching the status color from the design.

---

### User Story 2 - Section and Item Context Menus (Priority: P1)

A user right-clicks or clicks the "..." menu on a section header or item row to access quick actions. The section context menu shows: Edit, Move, Copy, New list from group, Archive group, Delete group, and Insert a to-do. The item context menu shows: Edit, Move, Copy, Archive, and Delete item. These match the design reference exactly.

**Why this priority**: Context menus are the primary way users perform bulk actions. Without them, users must open each item individually.

**Independent Test**: Click the "..." on a section header and verify all menu options appear. Click the "..." on an item and verify item-specific options appear. Execute each action and verify it works.

**Acceptance Scenarios**:

1. **Given** a section header with items, **When** clicking the section's "..." menu, **Then** a dropdown appears with: Edit, Move..., Copy..., New list from group, Archive group, Delete group, Insert a to-do.
2. **Given** an item in the list, **When** clicking the item's "..." context menu, **Then** a dropdown appears with: Edit, Move..., Copy..., Archive, Delete.
3. **Given** a section context menu open, **When** clicking "Archive group", **Then** the section and all its items are archived and removed from view.
4. **Given** a section context menu open, **When** clicking "Delete group", **Then** a confirmation dialog appears before permanent deletion.
5. **Given** an item context menu open, **When** clicking "Delete", **Then** the item is removed from the list.

---

### User Story 3 - Notes Editor Save Button (Priority: P1)

A user editing notes on a TODO item sees a "Save" button (not "Done") when in edit mode. Clicking "Save" persists the note content and updates the display immediately with the saved content. The button styling matches the design reference (purple branded button).

**Why this priority**: Notes are a core feature and the save behavior must be clear and reliable. "Done" is ambiguous — "Save" communicates the action precisely.

**Independent Test**: Open an item, click Edit on notes, type content, click Save, verify the content persists and the display updates.

**Acceptance Scenarios**:

1. **Given** a user is viewing an item's notes, **When** they click the Edit button, **Then** the notes area becomes editable with a rich text toolbar and a "Save" button appears.
2. **Given** a user is editing notes, **When** they click "Save", **Then** the note content is persisted, the editor closes, and the display shows the updated content.
3. **Given** a user is editing notes, **When** they click "Save", **Then** the Save button label and style match the design reference (not "Done").

---

### User Story 4 - Assignee Picker from Collaborator Pool (Priority: P2)

An editor on a shared list (or the owner) can assign collaborators to an item by selecting from a picker that shows all list members (owner + collaborators). The picker shows user names and avatars. Assigned users appear in the "Assigned to" card with the ability to remove them.

**Why this priority**: Assignment is essential for collaboration. The picker must show the right pool of people.

**Independent Test**: Open an item on a shared list, use the assignee picker to add a collaborator, verify their avatar appears. Remove them and verify they're removed.

**Acceptance Scenarios**:

1. **Given** a shared list with 3 collaborators, **When** an editor opens the assignee picker on an item, **Then** all list members (owner + collaborators) appear as selectable options with names and avatars.
2. **Given** an item with no assignees, **When** the user selects a collaborator from the picker, **Then** that person's avatar and name appear in the "Assigned to" card.
3. **Given** an item with an assignee, **When** the user clicks the remove button next to the assignee, **Then** the assignee is removed from the item.
4. **Given** a personal list (no collaborators), **When** the user opens the assignee picker, **Then** only the owner appears as an option.

---

### User Story 5 - Due Date Selection with Calendar (Priority: P2)

A user can set or change the due date on a TODO item using a date picker. The date picker matches the design reference (calendar overlay). The selected date appears in the "Due Date" card with a formatted display. The due date also appears as a badge on the list view item row.

**Why this priority**: Due dates are fundamental to task management. Users need to set deadlines easily.

**Independent Test**: Open an item, click the due date area, select a date from the calendar, verify it saves and displays correctly.

**Acceptance Scenarios**:

1. **Given** an item with no due date, **When** the user clicks the due date card, **Then** a date picker (calendar) overlay appears.
2. **Given** the date picker is open, **When** the user selects a date, **Then** the due date is saved and displayed in the card as a formatted date (e.g., "March 10, 2026").
3. **Given** an item with a due date set, **When** the user clicks the due date card, **Then** the date picker opens pre-selected to the current due date.
4. **Given** an item with a due date, **When** the user clears the date, **Then** the due date is removed and the card shows an empty/prompt state.

---

### User Story 6 - Notify on Complete Picker (Priority: P2)

An editor can add collaborators to the "Notify on Complete" list for an item. The picker shows all list members. Users on the notify list receive an email when the item is marked done.

**Why this priority**: Notification management is tightly coupled with collaboration — users need to control who gets notified.

**Independent Test**: Open an item, use the notify picker to add a collaborator, mark the item done, verify the email is sent.

**Acceptance Scenarios**:

1. **Given** a shared list, **When** an editor opens the "Notify on Complete" section on an item, **Then** they see all list members as selectable options.
2. **Given** an item with no notify users, **When** the editor adds a collaborator, **Then** that person appears in the notify list.
3. **Given** an item with a user on the notify list, **When** the editor removes them, **Then** the user is removed from the notify list.

---

### User Story 7 - File Attachments Upload and Display (Priority: P2)

A user can upload file attachments to a TODO item and see them displayed as file cards showing the filename, file type icon, and file size. The display matches the design reference (horizontal card layout with icons).

**Why this priority**: Attachments add essential context to tasks (mockups, documents, references).

**Independent Test**: Open an item, upload a file, verify it appears as a card with the correct name, icon, and size. Upload multiple files and verify the listing.

**Acceptance Scenarios**:

1. **Given** an item with no attachments, **When** the user clicks the Upload button, **Then** a file selection dialog appears.
2. **Given** the user selects a file, **When** the upload completes, **Then** the file appears as a card showing: filename, file type icon (image/document/spreadsheet), and file size.
3. **Given** an item with multiple attachments, **When** viewing the item, **Then** all attachments display in a horizontal scrollable layout matching the design.
4. **Given** an attachment card, **When** the user clicks on it, **Then** the file downloads or opens in a new tab.
5. **Given** an attachment, **When** the user clicks the delete/remove action, **Then** the attachment is removed from the item.

---

### Edge Cases

- What happens when a user uploads a file larger than the server limit? The system shows a user-friendly error message with the maximum file size.
- What happens when the notes editor loses connection mid-save? The system retains the unsaved content in the editor and shows an error prompting retry.
- What happens when a user tries to set a due date in the past? The system allows it (for tracking overdue items) but displays it with "overdue" styling.
- What happens when all collaborators are already assigned to an item? The assignee picker shows no available members with a message like "All members assigned."
- What happens when a context menu action fails (e.g., archive on a list with no permission)? The system shows an appropriate error and the menu closes.
- What happens when the user uploads a file type that is not an image, PDF, or document? The system accepts all file types but uses a generic file icon.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each item row on the list view MUST display a colored due date badge (when set) with urgency-based styling: green for distant, yellow for approaching (≤3 days), red for overdue.
- **FR-002**: Each item row MUST display a priority indicator dot matching the item's priority level (none=hidden, low=teal, medium=blue, high=amber, urgent=red), matching the design color scheme.
- **FR-003**: Each item row MUST display assignee avatar(s) when assigned, showing up to 2 avatars with a +N overflow indicator for additional assignees.
- **FR-004**: Section headers MUST have a context menu ("..." trigger) with options: Edit, Move, Copy, New list from group, Archive group, Delete group, Insert a to-do.
- **FR-005**: Item rows MUST have a context menu ("..." trigger) with options: Edit, Move, Copy, Archive, Delete.
- **FR-006**: The Notes section MUST show a "Save" button (not "Done") when in edit mode, styled as a branded/primary button per the design reference.
- **FR-007**: Clicking "Save" on notes MUST persist the content and immediately update the displayed notes.
- **FR-008**: The "Assigned to" card MUST display a picker showing all list members (owner + collaborators) for selection, with the ability to add and remove assignees.
- **FR-009**: The "Due Date" card MUST provide a date picker (calendar overlay) for selecting and clearing due dates, with the selected date displayed in a human-readable format.
- **FR-010**: The "Notify on Complete" card MUST display a picker showing all list members for adding and removing notification recipients.
- **FR-011**: The Attachments section MUST allow file uploads and display each attachment as a card with filename, file type icon, and file size.
- **FR-012**: Attachment cards MUST allow downloading the file and deleting the attachment.
- **FR-013**: All context menu actions (edit, move, copy, archive, delete) MUST function correctly and provide appropriate confirmation for destructive actions.
- **FR-014**: The Notes editor toolbar buttons MUST match the visual design reference (formatting icons, spacing, styling).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every item with a due date displays a correctly colored badge on the list view — 100% consistency with the design reference.
- **SC-002**: Every item with a priority displays the correct colored dot — 100% match with the design color scheme.
- **SC-003**: Users can set a due date on an item in under 5 seconds using the calendar picker.
- **SC-004**: Users can upload a file attachment and see it displayed as a card within 3 seconds of upload completion.
- **SC-005**: All context menu options execute their action successfully on first click — zero broken or no-op menu items.
- **SC-006**: The Notes "Save" button persists content and updates the display within 1 second of clicking.
- **SC-007**: The assignee and notify pickers show the correct pool of list members — zero missing or extra users.

## Assumptions

- **Existing UI foundation**: The TODO List Detail and TODO Item Detail views already exist with basic functionality. This feature polishes them to match the design reference — it does not rebuild them from scratch.
- **Collaboration feature is merged**: The List Collaboration feature (005) is merged, providing the collaborator pool for assignee and notify pickers. On personal lists (no collaborators), pickers show only the owner.
- **Active Storage is configured**: File uploads use the existing Active Storage setup. No new storage configuration is needed.
- **Rich text editor exists**: The Lexxy editor is already integrated for notes. This feature adjusts the button label and save behavior, not the editor itself.
- **Design reference is authoritative**: Where the design and current implementation differ, the design wins. All visual details (colors, spacing, icons, layout) should match the .pen file screenshots.
- **"New list from group" deferred**: The section context menu option "New list from group" (creating a new TodoList from a section's items) requires a new controller endpoint and is deferred to a future feature. It will appear as a disabled menu item with a "Coming soon" tooltip.
