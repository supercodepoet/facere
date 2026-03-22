# Feature Specification: TODO List Items Management

**Feature Branch**: `003-todo-list-items`
**Created**: 2026-03-21
**Status**: In Progress — Core implementation complete, Copilot code review resolved, CI green
**Input**: User description: "Flesh out the creation and management of TODO list items with inline creation, sections, reordering, context menus, and a rich item detail view"

## Clarifications

### Session 2026-03-21

- Q: What fields does a TODO item have? -> A: Derived from `todo-list-item-screens.pen` TODO Item Detail screen: name, completed status, due date, priority, status (Todo/In Progress/Done), notes (rich text), checklist (sub-items), attachments (files), tags, and position for ordering.
- Q: How are items created? -> A: Inline creation directly within the list view. User types into an active input row with Enter to save and Esc to cancel. After saving, the cursor stays active for rapid consecutive creation.
- Q: How are sections created? -> A: Inline creation with a section name input and an icon picker dropdown. Enter to create, with icon selection optional.
- Q: How is reordering done? -> A: Drag-and-drop via a grip handle on each item and section. Items can be reordered within sections, moved between sections, or placed outside sections. Sections can be reordered with all their items.
- Q: What context menu actions exist for items? -> A: Edit, Move..., Copy..., Archive, Delete (red), Insert a to-do.
- Q: What context menu actions exist for sections? -> A: Edit, Move..., Copy..., New list from group, Archive group, Delete group (red), Insert a to-do.
- Q: What does the TODO Item Detail view contain? -> A: Left column with item header (status/priority badges, title, metadata), notes section, checklist section, attachments section, and comments section. Right column with status selector, assignees, due date, notify on complete, tags, and action buttons (Mark Complete, Delete Item).
- Q: Should Assignees, Comments, and Notify on Complete implement full multi-user collaboration? -> A: No. Single-user stubs: show the UI sections, user can assign to self, add personal notes as "comments". The data model will be established for future multi-user expansion but no team/workspace model is built in this feature.
- Q: How should Archive behave? -> A: Soft-hide: set an `archived` flag on items and sections, filter them from the default view. No restore UI is built in this feature — that will come when an archive view screen is designed.
- Q: What format should Notes use? -> A: Rich text via ActionText (Trix editor). Notes are stored as HTML and rendered as formatted content. This supports paragraphs, bullet lists, and basic formatting.
- Q: How does the user navigate to the item detail view? -> A: Full page navigation via standard Rails show action with Turbo Drive. The item detail is a dedicated page, not a panel or modal.
- Q: How many priority levels exist? -> A: Four: None (no dot, default), Low (teal/green dot), Medium (orange dot), High (red dot).

### Implementation Learnings (2026-03-22)

- **Fizzy is NOT an editor**: "Fizzy" (basecamp/fizzy) is 37signals' Kanban project management tool, not a text editor. The actual rich text editor successor to Trix is "Lexxy" (basecamp/lexxy, currently beta). ActionText with Trix was used instead as a stable, built-in Rails solution.
- **`wa-dropdown` for context menus**: Web Awesome Pro does NOT have `wa-menu` or `wa-menu-item` components. Use `wa-dropdown` + `wa-dropdown-item` for all menu patterns. `wa-select` event fires on item selection.
- **Stimulus controller scope and targets**: `data-controller` must be on an ancestor element of ALL targets. When using `wa-dropdown` with hidden form targets, wrap both in a container div with the controller attribute — targets CANNOT be siblings of the controller element.
- **Turbo Stream vs HTML responses on detail pages**: Turbo Stream responses that replace list-row partials will fail on the item detail page (the target DOM elements don't exist). Use `data: { turbo: false }` on detail-page forms to force full HTML redirects.
- **Turbo Frames and navigation**: Links inside `turbo_frame_tag` are intercepted by Turbo, which tries to find a matching frame in the response. For full-page navigation (e.g., item title → detail page), add `data: { turbo_frame: "_top" }` to the link.
- **Drag-and-drop with Turbo Frames**: The `draggable` attribute must be on the `turbo-frame` element itself (not an inner div), since the frame is what moves in the DOM. Use `data-item-id` attributes for identification instead of relying on DOM `id` attributes.
- **Duplicate DOM IDs with turbo_frame_tag**: `turbo_frame_tag dom_id(item)` creates `<turbo-frame id="...">`. DO NOT also set the same `id` on an inner element — this causes duplicate IDs breaking JS lookups and Turbo replacements.
- **Scoped associations and controller lookups**: When `has_many` uses a scope (e.g., `-> { active }`), controller `find` calls will exclude records matching that scope (e.g., archived sections can't be found). Use an unscoped association (e.g., `all_todo_sections`) for controller lookups that should operate on all records.
- **Duplicate `dependent: :destroy`**: Having `dependent: :destroy` on both a scoped and unscoped association pointing at the same table causes duplicate destroy attempts. Only put `dependent: :destroy` on the unscoped association.
- **`assigned_to_user_id` security**: Even in a single-user-stubs model, NEVER permit arbitrary user IDs from client params. Always force ownership fields server-side (e.g., `permitted[:assigned_to_user_id] = Current.user.id`).
- **Position shift on item creation**: When prepending items at position 0, shift existing positions BEFORE saving the new item (in a transaction), not after — otherwise the new item also gets shifted.
- **`button_to` with blocks**: When using `button_to` with a block (for icon content), do NOT pass a label string as the first argument. The block provides the content; the first arg must be the URL. Passing both causes `stringify_keys` errors.
- **`showPicker()` browser compatibility**: `HTMLInputElement#showPicker()` is not supported in all browsers. Always wrap in feature detection and try/catch.
- **Case-insensitive DB constraints**: Always add database-level unique indexes with `lower(name)` for user-scoped name fields, matching the model validation. Applied to both `todo_lists` and `tags` tables.
- **System test sign-in with Web Awesome**: Dispatch multiple events (`wa-input`, `wa-change`, `input`, `change`) when setting wa-input values in tests to ensure form data syncs through shadow DOM.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create TODO Items Inline (Priority: P1)

A user opens a TODO list and quickly adds items by typing directly into an inline input field. The creation flow is optimized for speed — pressing Enter saves the current item and immediately presents a new empty input for the next item. This allows users to rapidly populate a list without navigating away or opening forms.

**Why this priority**: Item creation is the most fundamental action. Without it, TODO lists have no content. The inline creation pattern is the primary differentiator for encouraging fast, frictionless use.

**Independent Test**: Can be fully tested by opening a TODO list, typing item names, pressing Enter, and verifying items appear in the list.

**Acceptance Scenarios**:

1. **Given** a user viewing an empty TODO list, **When** they click "Add Item" or the empty state prompt, **Then** an inline input row appears with a text field, checkbox placeholder, and keyboard hints (Enter to save, Esc to cancel).
2. **Given** a user with an active inline input, **When** they type an item name and press Enter, **Then** the item is saved, appears in the list, and a new empty input row appears for the next item.
3. **Given** a user with an active inline input, **When** they press Escape, **Then** the input is dismissed without creating an item.
4. **Given** a user with an active inline input, **When** they submit without typing a name, **Then** no item is created and the input remains active.
5. **Given** a user creating an item inline, **When** the item is saved, **Then** quick action buttons (Assign, Due date, Priority) appear below the input for optional metadata.
6. **Given** a user viewing a list with items, **When** they click the "Add Item" button in the top bar, **Then** a new inline input row appears at the top of the unsectioned items area.
7. **Given** a user viewing a section, **When** they click the "Add item" button in the section header, **Then** a new inline input row appears within that section.

---

### User Story 2 - View TODO List Detail with Items and Sections (Priority: P1)

A user views a TODO list that contains both unsectioned items and items organized into named sections. Each item displays its name, completion status, due date badge (color-coded by urgency), assigned avatar, and priority indicator. Sections are collapsible with a count of contained items.

**Why this priority**: This is the primary view users interact with daily. All other features (editing, reordering, detail view) build on this list display.

**Independent Test**: Can be fully tested by navigating to a populated TODO list and verifying all items, sections, badges, and indicators display correctly.

**Acceptance Scenarios**:

1. **Given** a user viewing a TODO list with unsectioned items, **When** the list loads, **Then** unsectioned items appear under a "Items without section" header, each showing a drag handle, checkbox, title, and any due date/assignee/priority indicators.
2. **Given** a user viewing a TODO list with sections, **When** the list loads, **Then** each section displays a header with drag handle, collapse chevron, icon, name, item count badge, "Add item" button, and a more options (ellipsis) menu.
3. **Given** a TODO item with a due date, **When** the list renders, **Then** the due date is displayed as a color-coded badge: red for overdue, amber/yellow for upcoming, blue for future dates, green for far-future/completed.
4. **Given** a TODO item that is completed, **When** the list renders, **Then** the item displays with a teal checkmark, reduced opacity, and the title visually distinguished from incomplete items.
5. **Given** a user viewing a section header, **When** they click the collapse chevron, **Then** the section's items are hidden/shown and the chevron rotates accordingly.
6. **Given** a TODO list with items in the top bar, **When** the user views the top bar, **Then** they see a back button, list emoji + title with edit pencil icon, "Add Section" button, and "Add Item" button (purple, prominent).

---

### User Story 3 - Create Sections Inline (Priority: P1)

A user creates a new section within a TODO list to organize their items into named groups. Section creation happens inline with an icon picker for choosing a visual identifier.

**Why this priority**: Sections are essential for organizing items. The inline creation pattern keeps users in flow without navigating away.

**Independent Test**: Can be fully tested by clicking "Add Section", typing a name, optionally selecting an icon, and pressing Enter.

**Acceptance Scenarios**:

1. **Given** a user viewing a TODO list, **When** they click the "Add Section" button in the top bar, **Then** an inline section input appears with an icon picker button, text field, and keyboard hint (Enter to create).
2. **Given** a user with an active section input, **When** they type a section name and press Enter, **Then** the section is created and appears in the list with an empty state hint ("No items yet — click Add item to get started").
3. **Given** a user creating a section, **When** they click the icon picker button, **Then** a dropdown grid of icons appears for selection.
4. **Given** a user creating a section, **When** they select an icon and submit, **Then** the section is created with the chosen icon displayed in the section header.
5. **Given** a user creating a section, **When** they submit without selecting an icon, **Then** the section is created with a default icon.
6. **Given** a user creating a section, **When** they press Escape, **Then** the section input is dismissed without creating a section.

---

### User Story 4 - Edit Items and Sections (Priority: P2)

A user edits existing items and sections to update names, icons, and other details. Editing is accessible via context menus or direct interaction.

**Why this priority**: Users need to correct mistakes, update item names, and modify section details after creation. This is a natural follow-up to creation.

**Independent Test**: Can be fully tested by right-clicking an item or section, selecting Edit, modifying the content, and verifying changes persist.

**Acceptance Scenarios**:

1. **Given** a user viewing a TODO item, **When** they right-click or open the item's context menu, **Then** they see options: Edit, Move..., Copy..., Archive, Delete, Insert a to-do.
2. **Given** a user selecting "Edit" from an item's context menu, **When** the edit mode activates, **Then** the item name becomes editable inline and the user can modify it.
3. **Given** a user viewing a section header, **When** they click the ellipsis menu, **Then** they see options: Edit, Move..., Copy..., New list from group, Archive group, Delete group (red text), Insert a to-do.
4. **Given** a user selecting "Edit" from a section's context menu, **When** the edit mode activates, **Then** the section name and icon become editable.
5. **Given** a user editing an item or section name, **When** they press Enter or click away, **Then** the changes are saved.
6. **Given** a user editing an item or section name, **When** they press Escape, **Then** the changes are discarded.

---

### User Story 5 - Reorder Items and Sections via Drag and Drop (Priority: P2)

A user reorders items within a section, between sections, or at the list level by dragging them using the grip handle. Sections can also be reordered, moving all contained items with them.

**Why this priority**: Reordering is essential for task management — users prioritize and reorganize as their work evolves. Depends on items and sections being created first.

**Independent Test**: Can be fully tested by dragging an item or section to a new position and verifying the order persists after page reload.

**Acceptance Scenarios**:

1. **Given** a user viewing a TODO list with multiple items, **When** they click and hold the grip handle on an item, **Then** the item lifts with a purple border, slight rotation, and shadow effect, and a hint tooltip appears ("Click & hold on drag to reorder").
2. **Given** a user dragging an item within the same section, **When** they drop it at a new position, **Then** the item moves to the new position and the order is saved.
3. **Given** a user dragging an item, **When** they drop it into a different section, **Then** the item moves to that section at the drop position.
4. **Given** a user dragging an item from a section, **When** they drop it into the unsectioned area, **Then** the item is removed from its section and placed in the unsectioned items.
5. **Given** a user dragging a section header, **When** they drop it at a new position, **Then** the entire section (header and all items) moves to the new position.
6. **Given** a user who has reordered items, **When** they reload the page, **Then** the new order is preserved.

---

### User Story 6 - Toggle Item Completion (Priority: P1)

A user marks items as complete or incomplete by clicking the checkbox. Completed items are visually distinguished with a teal checkmark and reduced opacity.

**Why this priority**: Checking off items is the core interaction loop of a TODO app. This is fundamental to the user experience.

**Independent Test**: Can be fully tested by clicking an item's checkbox and verifying the visual state changes and persists.

**Acceptance Scenarios**:

1. **Given** a user viewing an incomplete TODO item, **When** they click the checkbox, **Then** the item is marked as completed with a teal checkmark icon, the text style changes, and the item appears at reduced opacity.
2. **Given** a user viewing a completed TODO item, **When** they click the checkmark, **Then** the item is marked as incomplete and returns to its normal visual state.
3. **Given** a user toggling item completion, **When** the toggle completes, **Then** the section's item count badge updates and the list's overall completion percentage updates.

---

### User Story 7 - View TODO Item Detail (Priority: P2)

A user clicks on a TODO item to view its full detail page. The detail view shows comprehensive information organized into a left content column and a right metadata sidebar.

**Why this priority**: The detail view is where users add depth to their items (notes, checklists, files). It builds on the list view and depends on items existing.

**Independent Test**: Can be fully tested by clicking on a TODO item and verifying all detail sections display correctly with the ability to edit each section.

**Acceptance Scenarios**:

1. **Given** a user viewing a TODO list, **When** they click on an item's title, **Then** they are navigated to the item's detail view showing status badges, title, creation date, and section assignment.
2. **Given** a user on an item detail page, **When** they view the left column, **Then** they see sections for: Notes (with edit button), Checklist (with progress badge and add button), Attachments (with count badge and upload button), and Comments (with input field).
3. **Given** a user on an item detail page, **When** they view the right column, **Then** they see: Status selector (Todo/In Progress/Done), Due Date with calendar display, Tags, and Actions (Mark Complete, Delete Item).
4. **Given** a user viewing the status selector, **When** they click a different status (e.g., "In Progress"), **Then** the item's status updates and the badge reflects the change.
5. **Given** a user viewing the item detail, **When** they click "Mark Complete", **Then** the item is marked as completed and the status updates to "Done".
6. **Given** a user viewing the item detail, **When** they click "Delete Item", **Then** they are prompted with a confirmation and the item is permanently removed.

---

### User Story 8 - Manage Item Notes (Priority: P3)

A user adds and edits rich text notes on a TODO item to capture additional context, instructions, or thoughts.

**Why this priority**: Notes add depth to items but are not required for basic item management. Users can function without them initially.

**Independent Test**: Can be fully tested by opening an item detail, clicking edit on the notes section, typing content, and verifying it saves.

**Acceptance Scenarios**:

1. **Given** a user on an item detail page, **When** they view the Notes section, **Then** they see existing notes content with an edit (pencil) button.
2. **Given** a user clicking the edit button on Notes, **When** the editor activates, **Then** they can type and format rich text including paragraphs and bullet lists.
3. **Given** a user editing notes, **When** they finish and save, **Then** the rich text content persists and displays as formatted HTML (paragraphs, lists, etc.).

---

### User Story 9 - Manage Item Checklist (Priority: P3)

A user creates and manages a checklist within a TODO item to break down the task into smaller sub-steps with individual completion tracking.

**Why this priority**: Checklists provide granular task breakdown. Useful but not essential for basic TODO management.

**Independent Test**: Can be fully tested by opening an item detail, adding checklist items, and toggling their completion.

**Acceptance Scenarios**:

1. **Given** a user on an item detail page, **When** they view the Checklist section, **Then** they see existing checklist items with checkboxes, a progress badge (e.g., "4/7"), and an "Add" button.
2. **Given** a user clicking the "Add" button, **When** they type a checklist item name and submit, **Then** the new item appears in the checklist.
3. **Given** a user viewing a checklist item, **When** they click its checkbox, **Then** the item is marked done (with strikethrough text) and the progress badge updates.
4. **Given** a user viewing the checklist progress, **When** items are completed, **Then** the progress badge shows the ratio of completed to total items.

---

### User Story 10 - Manage Item Due Date and Priority (Priority: P2)

A user sets a due date and priority level on a TODO item. These are displayed as color-coded badges in the list view and in the item detail sidebar.

**Why this priority**: Due dates and priorities are core task management features that help users organize and triage their work.

**Independent Test**: Can be fully tested by setting a due date and priority on an item and verifying they display correctly in both list and detail views.

**Acceptance Scenarios**:

1. **Given** a user creating an item inline, **When** they click the "Due date" quick action, **Then** a date picker appears for selecting a due date.
2. **Given** a user creating an item inline, **When** they click the "Priority" quick action, **Then** priority options appear for selection.
3. **Given** a user on an item detail page, **When** they view the Due Date card in the right column, **Then** they see the due date with a calendar icon and can modify it.
4. **Given** an item with a due date in the past, **When** the list renders, **Then** the due badge shows "Overdue" in red (#FEE2E2 background, #991B1B text).
5. **Given** an item with a due date in the near future, **When** the list renders, **Then** the due badge shows the date in amber (#FEF3C7 background, #92400E text).
6. **Given** an item with a due date further out, **When** the list renders, **Then** the due badge shows the date in blue (#DBEAFE background, #1E40AF text).

---

### User Story 11 - Manage Item Tags (Priority: P3)

A user adds tags to a TODO item to categorize and label it. Tags are displayed as colored pills in the item detail view.

**Why this priority**: Tags provide categorization but are supplementary to core item management.

**Independent Test**: Can be fully tested by opening an item detail, adding tags, and verifying they display correctly.

**Acceptance Scenarios**:

1. **Given** a user on an item detail page, **When** they view the Tags card, **Then** they see existing tags as colored pills.
2. **Given** a user clicking to add a tag, **When** they type a tag name, **Then** the tag is created and appears in the Tags card.
3. **Given** a user viewing a tag, **When** they click to remove it, **Then** the tag is removed from the item.

---

### User Story 12 - Manage Item Attachments (Priority: P3)

A user attaches files to a TODO item for reference materials, images, or documents.

**Why this priority**: Attachments enrich items but are not needed for core task tracking. Depends on item creation and detail view.

**Independent Test**: Can be fully tested by opening an item detail, uploading a file, and verifying it appears in the Attachments section.

**Acceptance Scenarios**:

1. **Given** a user on an item detail page, **When** they view the Attachments section, **Then** they see existing files as cards showing file type icon and name, with a count badge and upload button.
2. **Given** a user clicking the upload button, **When** they select a file, **Then** the file is uploaded and appears as a new card in the attachments grid.
3. **Given** a user viewing an attachment, **When** they click on it, **Then** they can download or preview the file.

---

### User Story 13 - Delete Items and Sections (Priority: P2)

A user deletes items or entire sections (with all contained items) via context menus. Deletion is destructive and permanent.

**Why this priority**: Users need to clean up completed or irrelevant items and sections. Important for list hygiene.

**Independent Test**: Can be fully tested by right-clicking an item or section, selecting Delete, and verifying removal.

**Acceptance Scenarios**:

1. **Given** a user selecting "Delete" from an item's context menu, **When** they confirm, **Then** the item is permanently removed from the list.
2. **Given** a user selecting "Delete group" from a section's context menu, **When** they confirm, **Then** the section and all its items are permanently removed.
3. **Given** a user deleting the last item in a section, **When** the deletion completes, **Then** the section shows its empty state hint.

---

### User Story 14 - Move and Copy Items (Priority: P3)

A user moves or copies items between sections within the same list, or potentially to other lists. This is accessible via the context menu.

**Why this priority**: Moving and copying provide organizational flexibility but are secondary to creation, editing, and reordering.

**Independent Test**: Can be fully tested by right-clicking an item, selecting Move or Copy, choosing a destination, and verifying the result.

**Acceptance Scenarios**:

1. **Given** a user selecting "Move..." from an item's context menu, **When** a destination picker appears, **Then** they can choose a section (or unsectioned) within the current list to move the item to.
2. **Given** a user selecting "Copy..." from an item's context menu, **When** they choose a destination, **Then** a duplicate of the item is created at the destination.
3. **Given** a user selecting "Move..." from a section's context menu, **When** they choose a destination, **Then** the section and its items are relocated.

---

### User Story 15 - Security & Authorization (Priority: P1)

All TODO item and section operations are scoped to the authenticated user's TODO lists. No user can view, edit, or delete items belonging to another user's lists. Unauthenticated access is redirected to sign-in.

**Acceptance Scenarios**:

1. **Given** an unauthenticated user, **When** they attempt any item or section action, **Then** they are redirected to sign in.
2. **Given** User A is signed in, **When** they attempt to access an item belonging to User B's list, **Then** they receive a 404 Not Found.
3. **Given** User A is signed in, **When** they attempt to modify a section in User B's list, **Then** they receive a 404 Not Found.
4. **Given** User A is signed in, **When** they create an item, **Then** the item is associated with their list (parameter injection of list_id is ignored if it doesn't belong to them).

---

### Edge Cases

- What happens when a user drags an item to a position between two sections? The item is placed in the unsectioned area at the nearest position.
- What happens when a user creates an item with a very long name? The system enforces a maximum length of 255 characters.
- What happens when a user deletes a section that contains items? All items in the section are permanently deleted with the section.
- What happens when a user tries to create a section with an empty name? The section is not created; a name is required.
- What happens when a user drags a completed item? It can be reordered like any other item.
- What happens when all items in a section are completed? The section remains visible with completed items shown at reduced opacity.
- What happens when a user clicks on a completed item? They can still access the detail view and edit it.
- What happens when a user sets a due date to today? The due badge displays in amber/warning style.
- What happens when a checklist item is the last one and gets completed? The progress badge shows full completion (e.g., "4/4").
- How does the system handle concurrent edits? Standard optimistic behavior — last write wins.
- What is the maximum section name length? 100 characters (matching existing model validation).
- What is the maximum number of items per list? No artificial limit.
- What is the maximum number of sections per list? No artificial limit.
- What happens when a user archives an item or section? The item/section is soft-hidden from the default list view via an `archived` flag. It remains in the database for future restore capability. No archive view or restore UI is included in this feature.

## Requirements *(mandatory)*

### Functional Requirements

**Inline Item Creation**

- **FR-001**: System MUST provide inline item creation directly within the list view, with a text input row showing a checkbox placeholder, text field, and keyboard hints.
- **FR-002**: System MUST save an item when the user presses Enter and immediately present a new empty input for the next item.
- **FR-003**: System MUST dismiss the input without creating an item when the user presses Escape.
- **FR-004**: System MUST NOT create an item if the name is empty.
- **FR-005**: System MUST display quick action buttons (Assign, Due date, Priority) below the active input row for optional metadata during creation.

**Inline Section Creation**

- **FR-006**: System MUST provide inline section creation with a name input and icon picker dropdown, activated by the "Add Section" button in the top bar.
- **FR-007**: System MUST create a section when the user presses Enter, with an optional icon selection.
- **FR-008**: System MUST provide a grid of icons for the user to choose from when creating a section.
- **FR-009**: System MUST assign a default icon if the user does not select one.

**List Detail View**

- **FR-010**: System MUST display unsectioned items under an "Items without section" header.
- **FR-011**: System MUST display section headers with: drag handle, collapse chevron, icon, name, item count badge, "Add item" button, and ellipsis more-options menu.
- **FR-012**: System MUST display each TODO item with: drag handle, checkbox, title, and optional due date badge, assignee avatar, and priority indicator.
- **FR-013**: System MUST display completed items with a teal checkmark, reduced opacity (50%), and visually distinguished title.
- **FR-014**: System MUST show color-coded due date badges: red (#FEE2E2/#991B1B) for overdue, amber (#FEF3C7/#92400E) for upcoming, blue (#DBEAFE/#1E40AF) for future, green (#D1FAE5/#065F46) for far-future.
- **FR-015**: System MUST allow sections to be collapsed and expanded via the chevron toggle.

**Item Completion**

- **FR-016**: System MUST toggle item completion when the user clicks the checkbox.
- **FR-017**: System MUST update the section item count and list completion percentage when an item's completion state changes.

**Context Menus**

- **FR-018**: System MUST provide an item context menu with: Edit, Move..., Copy..., Archive, Delete, Insert a to-do.
- **FR-019**: System MUST provide a section context menu with: Edit, Move..., Copy..., New list from group, Archive group, Delete group (red), Insert a to-do.
- **FR-020**: System MUST display "Delete" and "Delete group" in red/danger color.

**Drag and Drop Reordering**

- **FR-021**: System MUST support drag-and-drop reordering of items via a grip handle, with visual feedback (purple border, slight rotation, shadow).
- **FR-022**: System MUST allow items to be reordered within a section, between sections, or into/out of the unsectioned area.
- **FR-023**: System MUST support drag-and-drop reordering of sections (including all contained items).
- **FR-024**: System MUST persist reorder changes so they survive page reloads.

**Editing**

- **FR-025**: System MUST allow inline editing of item names via the context menu "Edit" action.
- **FR-026**: System MUST allow inline editing of section names and icons via the context menu "Edit" action.

**Deletion**

- **FR-027**: System MUST permanently delete items when the user confirms deletion from the context menu.
- **FR-028**: System MUST permanently delete sections and all contained items when the user confirms "Delete group".

**Move and Copy**

- **FR-029**: System MUST allow moving items between sections within the same list via a destination picker.
- **FR-030**: System MUST allow copying items to create duplicates at a chosen destination.
- **FR-031**: System MUST allow moving sections within a list via the section context menu.

**TODO Item Detail View**

- **FR-032**: System MUST display an item detail page with a left content column and right metadata sidebar.
- **FR-033**: System MUST display item status badges (e.g., "In Progress", "High Priority") and the item title prominently in the header.
- **FR-034**: System MUST display creation date and section assignment in the item header metadata row.
- **FR-035**: System MUST provide a Notes section with rich text content (via ActionText/Trix editor) and an edit button.
- **FR-036**: System MUST provide a Checklist section with individual sub-items, checkboxes, progress tracking badge, and an add button.
- **FR-037**: System MUST provide an Attachments section with file cards, a count badge, and an upload button.
- **FR-038**: System MUST provide a Status selector in the right sidebar with three options: Todo, In Progress, Done.
- **FR-039**: System MUST provide a Due Date card in the right sidebar with calendar display and date selection.
- **FR-040**: System MUST provide a Tags card in the right sidebar for adding and removing categorization tags.
- **FR-041**: System MUST provide action buttons: "Mark Complete" (green, prominent) and "Delete Item" (red, text style).

**Item Fields**

- **FR-042**: System MUST support a status field on items with values: Todo, In Progress, Done.
- **FR-043**: System MUST support a due date field on items (optional, date type).
- **FR-044**: System MUST support a priority field on items with four levels: None (no dot, default), Low (teal/green dot), Medium (orange dot), High (red dot).
- **FR-045**: System MUST support a notes field on items (optional, rich text stored as HTML via ActionText, supporting paragraphs, bullet lists, and basic formatting).
- **FR-046**: System MUST support a checklist on items as ordered sub-items with individual completion state.

**Security**

- **FR-047**: System MUST require authentication for all item and section actions.
- **FR-048**: System MUST scope all item and section operations through the authenticated user's TODO lists. Return 404 for unauthorized access.
- **FR-049**: System MUST ignore parameter injection attempts (e.g., submitting a todo_list_id belonging to another user).

### Key Entities

- **TODO Item**: An individual task within a TODO list. Key attributes: name (required, max 255 chars), completed (boolean), position (integer for ordering), status (Todo/In Progress/Done), due date (optional date), priority (optional: high/medium/low), notes (optional text). Belongs to a TODO list, optionally belongs to a section. Has many checklist items, attachments, and tags.
- **TODO Section**: A named grouping within a TODO list. Key attributes: name (required, max 100 chars), icon (optional string), position (integer for ordering). Belongs to a TODO list. Has many items.
- **Checklist Item**: A sub-task within a TODO item. Key attributes: name (required), completed (boolean), position (integer for ordering). Belongs to a TODO item.
- **Attachment**: A file associated with a TODO item. Key attributes: file reference, original filename. Belongs to a TODO item.
- **Tag**: A categorization label for a TODO item. Key attributes: name (required), color (optional). Associated with TODO items (many-to-many).

### Deferred Features / Future Work

The following features are visible in the design or were identified during implementation but deferred to future iterations:

- **Archive restore UI**: Archive sets an `archived` flag but no "View Archive" or "Restore" screen exists. Items/sections are hidden but recoverable via database.
- **Move and Copy dialogs**: Context menus show "Move..." and "Copy..." but the destination picker dialog is not yet implemented. Currently these actions are no-ops in the UI.
- **New list from group**: Section context menu shows "New list from group" but the action to create a new TodoList from a section's items is not implemented.
- **Insert a to-do**: Context menu "Insert a to-do" action should insert an inline item input at the clicked position. Currently a no-op.
- **Multi-user collaboration**: Assignees, Comments, and Notify on Complete are single-user stubs. Future work: team/workspace model, multi-user assignment, real-time threaded comments, notification system.
- **Drag-and-drop for sections**: Section headers currently do not support drag reordering (draggable attribute removed). Needs separate implementation for section-level reordering.
- **Inline item editing via context menu**: The "Edit" action in item context menus is not yet wired to toggle inline editing of item names.
- **Tag management UI**: Tags can be created and removed via controller, but the tag input UI (autocomplete, color picker) on the item detail page is not yet interactive.
- **Attachment preview/download**: File cards display filename and size but clicking does not yet preview or download.
- **Due date editing on detail page**: The Due Date card in the right sidebar displays the date but does not yet provide a date picker for modification.
- **Event listener cleanup in drag controller**: Drag reorder controller does not remove event listeners in `disconnect()`, which could cause duplicate handlers on Turbo navigation.
- **Multiple inline forms guard**: Multiple inline item/section forms can theoretically exist on the same page due to hardcoded IDs. Should implement global guard or unique IDs.

## Assumptions

- The existing TODO Item model (`todo_items` table) will be extended with new fields (status, due_date, priority, notes) rather than replaced.
- The existing TODO Section model (`todo_sections` table) will be extended with an icon field.
- Drag-and-drop reordering will use Stimulus controllers with server-side position persistence via Turbo Stream or standard HTTP requests.
- The Assignees, Comments, and Notify on Complete sections will be implemented as single-user stubs: the UI sections are present, the user can assign items to themselves, and add personal notes as "comments". The data model will support future multi-user expansion, but no team/workspace/invitation model is built in this feature.
- Archive sets an `archived` flag on items/sections and filters them from the default list view. No restore UI or archive listing screen is built in this feature — those will be added when the archive view is designed.
- Priority has four levels: None (no visual indicator, default), Low (teal/green dot), Medium (orange dot), High (red dot).
- Due date color coding is relative to the current date: overdue (past) = red, within 3 days = amber, within 2 weeks = blue, beyond 2 weeks = green.
- File attachments use standard file upload with reasonable size limits (e.g., 10MB per file).
- Tags are user-defined (not from a predefined set) with optional color selection.
- "New list from group" in the section context menu creates a new TODO list from the section's items. This is a convenience action that copies items to a new list.
- "Insert a to-do" in context menus inserts a new inline item input at the position of the context menu target.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create 5 TODO items in under 30 seconds using inline creation (Enter-to-save-and-continue flow).
- **SC-002**: Users can create a new section with an icon in under 10 seconds.
- **SC-003**: Users can reorder items via drag and drop with changes persisting across page reloads.
- **SC-004**: Users can view an item's full details (notes, checklist, due date, tags) within 1 second of clicking the item.
- **SC-005**: 100% of item and section operations are scoped to the authenticated user with no cross-user data leakage.
- **SC-006**: All context menu actions (edit, move, copy, delete, archive) complete successfully with appropriate feedback.
- **SC-007**: Completed items are visually distinguished at a glance with teal checkmark and reduced opacity.
- **SC-008**: Due date badges correctly reflect urgency through color coding (red/amber/blue/green) based on current date.
