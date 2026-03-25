# Feature Specification: Tag Management

**Feature Branch**: `009-tag-management`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "Update TODO Item Detail view to make tag management more rich — add/remove tags, create/edit/delete tags, search for tags, add custom colors to tags"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add and Remove Tags on a TODO Item (Priority: P1)

A user viewing a TODO item's detail screen can open a tag editor panel to quickly toggle tags on and off. The tag editor appears as a dropdown anchored to the Tags section on the right sidebar. Each tag in the list shows its color dot and name, with a checkmark indicating which tags are currently applied. Tapping a tag toggles it on or off immediately.

**Why this priority**: This is the core interaction — without the ability to assign and unassign tags, no other tag feature has value.

**Independent Test**: Can be fully tested by opening the tag editor on any TODO item, toggling tags, and confirming the item's displayed tags update in real time.

**Acceptance Scenarios**:

1. **Given** a TODO item with no tags and several tags exist for the user, **When** the user opens the tag editor and taps a tag, **Then** the tag is applied to the item, a checkmark appears next to it in the editor, and the tag appears in the item's tag list on the detail view.
2. **Given** a TODO item with an applied tag, **When** the user opens the tag editor and taps the applied tag, **Then** the tag is removed from the item, the checkmark disappears, and the tag is removed from the item's displayed tag list.
3. **Given** the tag editor is open, **When** the user clicks outside the editor or closes it, **Then** the editor dismisses and the item's tags reflect all changes made.

---

### User Story 2 - Search for Tags (Priority: P1)

When the tag editor is open, a search field at the top allows the user to filter the tag list by name. As the user types, the list narrows to show only tags whose names match the search text. This is essential when users have many tags.

**Why this priority**: Search is critical for usability — without it, users with many tags cannot efficiently find the one they need.

**Independent Test**: Can be tested by opening the tag editor, typing a partial tag name, and confirming only matching tags appear.

**Acceptance Scenarios**:

1. **Given** the tag editor is open with 10+ tags, **When** the user types "Des" in the search field, **Then** only tags containing "Des" (case-insensitive) appear in the list.
2. **Given** the tag editor is open with a search query entered, **When** the user clears the search field, **Then** all tags are shown again.
3. **Given** the tag editor is open, **When** the user types a query that matches no tags, **Then** the list is empty and the "Create new tag..." option remains visible.

---

### User Story 3 - Create a New Tag (Priority: P1)

From the tag editor, the user can create a new tag by clicking "Create new tag..." at the bottom of the list. A "Create New Tag" form appears with a name field and a color picker. The color picker shows preset color swatches and a custom color input. After creating, the tag is immediately available and applied to the current item.

**Why this priority**: Users must be able to create tags to build their taxonomy. Without creation, the system starts empty and unusable.

**Independent Test**: Can be tested by opening the tag editor, clicking "Create new tag...", filling in a name and selecting a color, and confirming the new tag appears in the list.

**Acceptance Scenarios**:

1. **Given** the tag editor is open, **When** the user clicks "Create new tag...", **Then** a "Create New Tag" form appears with a tag name field and color picker.
2. **Given** the Create New Tag form is visible, **When** the user enters a name, selects a preset color, and clicks "Create Tag", **Then** the tag is created with the chosen name and color, appears in the tag editor list, and is applied to the current item.
3. **Given** the Create New Tag form is visible, **When** the user enters a name and selects a custom color using the color input, **Then** the tag is created with the custom hex color.
4. **Given** the Create New Tag form is visible, **When** the user clicks "Cancel", **Then** the form closes and returns to the tag editor list without creating a tag.
5. **Given** the Create New Tag form is visible, **When** the user submits without entering a name, **Then** validation prevents creation and shows an appropriate error message.

---

### User Story 4 - Edit an Existing Tag (Priority: P2)

From the tag editor, the user can access a tag's context menu (via an ellipsis icon) and select "Edit Tag". An "Edit Tag" form appears pre-filled with the tag's current name and color. The user can change either and save. Changes propagate to all items that use this tag.

**Why this priority**: Editing is important for correcting mistakes or evolving tag names/colors, but not essential for initial use.

**Independent Test**: Can be tested by opening the tag editor, clicking the ellipsis on a tag, selecting "Edit Tag", changing the name or color, saving, and confirming the update appears everywhere the tag is used.

**Acceptance Scenarios**:

1. **Given** the tag editor is open, **When** the user hovers over or focuses on a tag row, **Then** an ellipsis (three-dot) menu icon appears on that row.
2. **Given** the ellipsis menu is visible on a tag, **When** the user clicks it, **Then** a context menu appears with "Edit Tag" and "Delete Tag" options.
3. **Given** the user clicks "Edit Tag" from the context menu, **Then** an "Edit Tag" form appears with the tag's current name and color pre-filled.
4. **Given** the Edit Tag form is visible, **When** the user changes the name and/or color and clicks "Save Changes", **Then** the tag is updated and all items using that tag reflect the new name and color.
5. **Given** the Edit Tag form is visible, **When** the user clicks "Cancel", **Then** the form closes without saving changes.

---

### User Story 5 - Delete a Tag (Priority: P2)

From the tag editor's ellipsis menu or from the Edit Tag form, the user can delete a tag. A confirmation dialog appears explaining the tag will be removed from all items. Upon confirmation, the tag is permanently deleted.

**Why this priority**: Deletion is needed for housekeeping but is less frequently used than creation or editing.

**Independent Test**: Can be tested by triggering delete from either entry point, confirming, and verifying the tag is removed from all items and the tag list.

**Acceptance Scenarios**:

1. **Given** the user clicks "Delete Tag" from the ellipsis context menu, **Then** a confirmation dialog appears showing the tag name and warning that the tag will be removed from all items across all lists.
2. **Given** the delete confirmation dialog is visible, **When** the user clicks "Delete Tag", **Then** the tag is permanently deleted, removed from all TODO items that had it, and removed from the tag editor list.
3. **Given** the delete confirmation dialog is visible, **When** the user clicks "Cancel", **Then** the dialog closes and the tag is not deleted.
4. **Given** the Edit Tag form is visible, **When** the user clicks "Delete this tag", **Then** the same delete confirmation dialog appears.

---

### Edge Cases

- What happens when a user tries to create a tag with the same name as an existing tag? The system prevents creation and informs the user the name is already taken (case-insensitive).
- What happens when a user deletes a tag that is applied to many items? The tag is removed from all items; those items simply lose that tag. No items are deleted.
- What happens when the search field is active and the user creates a new tag? The search resets and the new tag appears in the full list.
- How does the tag editor behave with no existing tags? The editor shows an empty state with only the "Create new tag..." option and the search field.
- What happens when a collaborator on the same list views tags? Tags are scoped per-user — each user manages their own tags independently.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a tag editor dropdown when the user activates the Tags section on the TODO item detail view.
- **FR-002**: The tag editor MUST show all of the user's tags with their color dot and name, with checkmarks on tags currently applied to the item.
- **FR-003**: Users MUST be able to toggle a tag on or off an item by clicking/tapping the tag row in the editor.
- **FR-004**: The tag editor MUST include a search field that filters the displayed tags by name in real time (case-insensitive partial match).
- **FR-005**: The tag editor MUST include a "Create new tag..." action at the bottom of the tag list.
- **FR-006**: The Create New Tag form MUST include a text field for the tag name and a color picker with preset color swatches.
- **FR-007**: The Create New Tag form MUST support custom color selection via a color input, allowing any hex color value.
- **FR-008**: The tag editor MUST show an ellipsis menu on each tag row (on hover/focus) with "Edit Tag" and "Delete Tag" options.
- **FR-009**: The Edit Tag form MUST pre-fill the current tag name and color, and allow changing either.
- **FR-010**: The Edit Tag form MUST include a "Delete this tag" action that triggers the delete confirmation flow.
- **FR-011**: The Delete Tag confirmation dialog MUST display the tag name and warn that the tag will be removed from all items across all lists.
- **FR-012**: System MUST enforce unique tag names per user (case-insensitive).
- **FR-013**: Tag color MUST be stored as a hex color value and displayed as a colored dot/badge throughout the interface.
- **FR-014**: When a tag is created from the Create New Tag form, it MUST be automatically applied to the current TODO item.
- **FR-015**: Changes to tags (create, edit, delete, toggle) MUST be reflected immediately in the UI without requiring a page reload.

### Key Entities

- **Tag**: A named label with a color that a user creates to categorize their TODO items. Key attributes: name (unique per user, case-insensitive), color (hex value). A tag belongs to one user and can be applied to many TODO items.
- **Item-Tag Association**: A relationship linking a specific TODO item to a specific tag. Enables many-to-many: one item can have many tags, one tag can be on many items.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can open the tag editor, find a tag, and apply it to an item in under 5 seconds.
- **SC-002**: Users can create a new tag with a custom name and color in under 10 seconds.
- **SC-003**: Tag search filters results as the user types, with results updating within each keystroke.
- **SC-004**: All tag changes (add, remove, create, edit, delete) reflect in the UI immediately without page reload.
- **SC-005**: Deleting a tag removes it from all associated items with a single confirmation step.
- **SC-006**: 95% of users can complete tag management tasks (create, assign, edit, delete) without external guidance on first attempt.

## Clarifications

### Session 2026-03-24

- Q: Are tags scoped per-user globally (shared across all lists) or per-list? → A: Per-user global — tags exist once per user across all lists. Delete confirmation text should read "removed from all items" (not "in this list").

## Assumptions

- Tags are scoped per user — each user has their own tag library. Tags created by one user are not visible to collaborators.
- The preset color palette has 7 colors: purple (#8B5CF6), red (#EF4444), orange (#F59E0B), blue (#2563EB), teal (#14B8A6), indigo (#6366F1), deep orange (#F97316). Pink was removed to prevent wrapping in the 280px-wide popover.
- The custom color input uses the native browser `<input type="color">` for hex color selection.
- The tag editor is anchored to the Tags section in the right sidebar of the TODO item detail view, appearing as an upward-opening popover near the "Manage tags" trigger link.
- Tag names have a maximum length of 50 characters (consistent with existing validation).
- The "Create new tag..." option is always visible at the bottom of the tag list, even when search is active.
- The trigger link always reads "+ Manage tags" regardless of whether tags are applied.

## Implementation Notes

### Session 2026-03-25

- The tag editor popover opens upward (above the trigger) to avoid being clipped by the page bottom.
- The create/edit form includes a live preview pill that shows exactly what the tag will look like — updates as you type the name and change the color.
- The edit form pre-populates all fields (name, color, preview, swatches, custom input, delete link data) via Stimulus JS, using a placeholder `Tag.new(id: 0)` in the HTML that gets overwritten.
- Context menus (ellipsis) use `position: fixed` with JS-calculated coordinates to escape the scrollable tag list's overflow clipping.
- Only one context menu can be open at a time — managed centrally by the tag-editor Stimulus controller.

## Future Enhancements

- **Keyboard navigation**: Arrow keys to navigate the tag list, Enter to toggle, Escape to close the editor. Required for WCAG 2.1 AA compliance.
- **System tests**: Full Capybara/Selenium tests for all tag editor flows (open, toggle, search, create, edit, delete, cancel).
- **Tag ordering options**: Sort by usage frequency, most recently created, or custom order.
- **Bulk tag operations**: Apply/remove tags across multiple items from the list view.
- **Tag usage counts**: Display the number of items using each tag in the editor dropdown.
- **Custom color picker component**: Replace the native `<input type="color">` with a styled picker for consistent cross-browser UX.
- **Empty state illustration**: More inviting onboarding when a user has no tags yet.

## Design References

Visual designs are defined in `designs/todo-list-item-screens.pen`:

- **Tag Editor Open**: Tag dropdown with search field, tag list with color dots and checkmarks, "Create new tag..." at bottom
- **Tag Editor - Ellipsis Menu**: Tag row context menu with "Edit Tag" and "Delete Tag" actions
- **Create New Tag**: Form with tag name field, preset color swatches, custom color input, Cancel/Create Tag buttons
- **Edit Tag**: Form with pre-filled tag name, color picker, "Delete this tag" link, Cancel/Save Changes buttons
- **Delete Tag Confirm**: Confirmation dialog with tag display, warning message, Cancel/Delete Tag buttons
