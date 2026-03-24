# Feature Specification: TODO List Management

**Feature Branch**: `002-todo-lists`
**Created**: 2026-03-21
**Status**: In Progress — Core CRUD complete, design polish applied, security hardened, Copilot code review resolved, CI green
**Input**: User description: "Create screens for managing TODO Lists including blank slate listing, list listing, list creation with name/icon/color/description/template, and blank slate for new list items"

## Clarifications

### Session 2026-03-21

- Q: What do the non-Blank templates pre-populate? → A: Templates combine named sections AND pre-populated items within those sections (e.g., Weekly template creates day-of-week sections with starter items in each; Shopping creates category sections like "Produce", "Dairy" with common items).
- Q: Does this feature include editing or deleting existing TODO lists? → A: Yes, both editing list details and deleting lists are in scope.
- Q: What specific colors are available for TODO list selection? → A: Color palette is defined in the visual reference file `initial-screens.pen`. Colors to be extracted from design during planning.
- Q: How should TODO lists be ordered on the listing screen? → A: Most recently created or updated first.
- Q: Is the create/edit list form a separate full page or a modal dialog? → A: Separate full page (standard new/edit pattern).

### Design Review Learnings (2026-03-21)

- The `.pen` design file is the source of truth for spacing, fonts, colors, and component sizes. Implementation must be validated against screenshots, not assumed from CSS alone.
- The error banner implementation uses custom HTML to exactly match the design's corner radius (16px), padding (14px 18px), colors (#FEE2E2 bg, #991B1B text), and close button behavior.
- Card design uses zinc-100 background (#F4F4F5) with a 4px left-only colored accent stripe, NOT white background with a full border. Corner radius is 24px.
- The design has 5 color swatches but the app has 6 colors. Form card width was increased from 620px to 660px to accommodate all 6 colors on one row.
- Color swatches are 26px (not 44px) and icon picker buttons are 40px (not 44px) per the design. Both the icon picker and color picker containers have a zinc-100 background fill with 16px corner radius.

### Copilot Code Review Learnings (2026-03-21)

- **HTML validity**: Never nest interactive elements (`<button>` inside `<a>`). List cards were restructured so the menu button is a sibling of the link, not nested inside it.
- **Stimulus event binding**: All Stimulus actions on buttons should use explicit `click->controller#method` syntax for consistency.
- **Stimulus controller scope**: A Stimulus `data-action` only fires if the element is inside (a descendant of) the element with the matching `data-controller`. The delete confirmation cancel button was moved to inline `onclick` because it lives inside a modal dialog, which is not a descendant of the trigger button's Stimulus controller.
- **No queries in views**: All DB queries must happen in the controller. `@todo_list.todo_items.where(...)` was moved to `@unsectioned_items` in the controller.
- **`.count` vs `.size`**: When associations are eager-loaded with `.includes()`, use `.size` (reads from memory) not `.count` (forces SQL COUNT). Applied to sidebar and section item counts.
- **Eager loading**: Index and show actions now use `.includes(:todo_items)` to prevent N+1 queries when rendering cards and sidebar.
- **Transaction safety**: `apply_template!` is now wrapped in a `transaction` block so template seeding is all-or-nothing.
- **Case-insensitive DB constraint**: Added a `lower(name)` unique index in SQLite to prevent race-condition duplicates that bypass model validation.
- **System tests**: Use `find()` to wait for element presence, then standard Capybara interactions. Never use top-level `await` in `execute_script` (it runs as classic script, not ES module). Use Capybara waits instead of `sleep`.
- **CI encryption keys**: Active Record encryption keys for test environment should be set in `config/environments/test.rb` with deterministic values so CI doesn't depend on `RAILS_MASTER_KEY`. Additionally, `RAILS_MASTER_KEY` should be stored as a GitHub secret.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View TODO Lists (Priority: P1)

A user navigates to their TODO Lists section. If they have no lists yet, they see a blank slate screen with a clear call-to-action to create their first list. If they already have lists, they see all their TODO lists displayed with their name, icon, color, and description.

**Why this priority**: This is the entry point for the entire feature. Users must be able to see their lists (or lack thereof) before any other interaction is possible.

**Independent Test**: Can be fully tested by navigating to the TODO Lists section and verifying the correct screen displays based on whether the user has existing lists or not.

**Acceptance Scenarios**:

1. **Given** a user with no TODO lists, **When** they navigate to the TODO Lists section, **Then** they see a blank slate screen with a message encouraging them to create their first list and a prominent "Create List" action.
2. **Given** a user with existing TODO lists, **When** they navigate to the TODO Lists section, **Then** they see all their lists displayed with each list's name, icon (if set), color indicator, and description.
3. **Given** a user with existing TODO lists, **When** they view the listing screen, **Then** they see a way to create a new list from this screen.

---

### User Story 2 - Create a New TODO List (Priority: P1)

A user creates a new TODO list by providing a name, selecting a color, optionally choosing an icon, adding an optional description, and selecting a starting template. The form enforces required fields and validates uniqueness of the list name.

**Why this priority**: Creating lists is the core action of this feature. Without it, the listing screens have no content to display.

**Independent Test**: Can be fully tested by navigating to the create screen, filling in the form fields, and submitting to verify a new list is created with the correct attributes.

**Acceptance Scenarios**:

1. **Given** a user on the create list screen, **When** they fill in the name, select a color, and submit the form, **Then** a new TODO list is created with the provided details, the "Blank" template selected by default, and the user is taken to their new list.
2. **Given** a user on the create list screen, **When** they submit without entering a name, **Then** they see a validation error indicating the name is required.
3. **Given** a user on the create list screen, **When** they enter a name that already exists in their account, **Then** they see a validation error indicating the name must be unique.
4. **Given** a user on the create list screen, **When** they view the template options, **Then** they see four choices (Blank, Project, Weekly, Shopping) with "Blank" pre-selected and cannot deselect all options.
5. **Given** a user on the create list screen, **When** they view the color options, **Then** the first color in the listing is pre-selected by default.
6. **Given** a user on the create list screen, **When** they choose not to select an icon, **Then** the form submits successfully without an icon.
7. **Given** a user on the create list screen, **When** they select the "Project" template and submit, **Then** the new list is created with the Project template applied.

---

### User Story 3 - View Empty TODO List (Priority: P2)

After creating a new TODO list, the user sees the list's blank slate screen — an empty state encouraging them to add their first items to the list.

**Why this priority**: This completes the creation flow and provides the transition point to adding items, but depends on list creation being functional first.

**Independent Test**: Can be fully tested by creating a new list and verifying the blank slate screen displays with the list's details and a prompt to add the first item.

**Acceptance Scenarios**:

1. **Given** a user who just created a new TODO list, **When** the list is created, **Then** they are taken to the list's screen showing a blank slate with the list name, color, and icon (if set) and a prompt to create their first item.
2. **Given** a user viewing an existing empty TODO list, **When** they navigate to that list, **Then** they see the blank slate screen with a call-to-action to add items.

---

### User Story 4 - Edit a TODO List (Priority: P2)

A user edits an existing TODO list's details — name, color, icon, and description. The same validation rules apply (name required, unique, etc.). The template cannot be changed after creation.

**Why this priority**: Editing is a natural follow-up to creation. Users will want to correct mistakes or update list details over time.

**Independent Test**: Can be fully tested by navigating to an existing list, editing its details, and verifying the changes are saved and reflected.

**Acceptance Scenarios**:

1. **Given** a user viewing one of their TODO lists, **When** they choose to edit the list, **Then** they see a form pre-populated with the list's current name, color, icon, and description.
2. **Given** a user editing a list, **When** they change the name to a valid unique name and save, **Then** the list is updated and the new name is reflected everywhere.
3. **Given** a user editing a list, **When** they change the name to one that already exists in their account, **Then** they see a validation error indicating the name must be unique.
4. **Given** a user editing a list, **When** they clear the name field and attempt to save, **Then** they see a validation error indicating the name is required.
5. **Given** a user editing a list, **When** they view the form, **Then** the template field is not editable (template is set at creation and cannot be changed).

---

### User Story 5 - Delete a TODO List (Priority: P3)

A user deletes an existing TODO list. The system asks for confirmation before permanently removing the list and all its sections and items.

**Why this priority**: Deletion is important for list management but is a destructive action used less frequently than creation or editing.

**Independent Test**: Can be fully tested by creating a list, deleting it, confirming the action, and verifying it no longer appears in the listing.

**Acceptance Scenarios**:

1. **Given** a user viewing one of their TODO lists, **When** they choose to delete the list, **Then** they are prompted with a confirmation dialog before the deletion proceeds.
2. **Given** a user confirming deletion, **When** they confirm, **Then** the list and all its sections and items are permanently removed and the user is returned to the TODO Lists listing screen.
3. **Given** a user confirming deletion of their only list, **When** they confirm, **Then** the list is removed and the user sees the blank slate screen.
4. **Given** a user presented with the delete confirmation, **When** they cancel, **Then** the list is not deleted and they remain on the list view.

---

### User Story 6 - Security & Authorization (Priority: P1)

All TODO list operations are scoped to the authenticated user. No user can view, edit, update, or delete another user's lists. Unauthenticated access is redirected to sign-in. Parameter injection (e.g., submitting a `user_id` field) must not allow assigning a list to a different user.

**Acceptance Scenarios**:

1. **Given** an unauthenticated user, **When** they attempt to access any TODO list action (index, show, new, create, edit, update, destroy), **Then** they are redirected to sign in.
2. **Given** User A is signed in, **When** they attempt to view User B's list (show), **Then** they receive a 404 Not Found.
3. **Given** User A is signed in, **When** they attempt to edit User B's list (edit), **Then** they receive a 404 Not Found.
4. **Given** User A is signed in, **When** they attempt to update User B's list (update), **Then** they receive a 404 Not Found and User B's list is unchanged.
5. **Given** User A is signed in, **When** they attempt to delete User B's list (destroy), **Then** they receive a 404 Not Found.
6. **Given** User A is signed in, **When** they view the listing, **Then** they see only their own lists, not User B's.
7. **Given** User A is signed in, **When** they submit a create form with a `user_id` parameter pointing to User B, **Then** the list is created under User A's account (parameter injection is ignored).

---

### Edge Cases

- What happens when a user tries to create a list with a name that differs only by case (e.g., "Groceries" vs "groceries")? Name uniqueness validation is case-insensitive — this is treated as a duplicate.
- What happens when a user enters a very long list name? The system enforces a maximum length of 100 characters.
- What happens when a user enters a very long description? The system enforces a maximum length of 500 characters.
- How does the system handle special characters in list names? All standard text characters are allowed.
- What happens if the user navigates away from the create or edit form with unsaved changes? Standard browser navigation behavior applies.
- What happens when a user deletes a list that has sections and items? All associated sections and items are permanently deleted along with the list.
- Can a user change the template of an existing list? No, the template is set at creation and cannot be changed afterward.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a blank slate screen when a user has no TODO lists, with a clear call-to-action to create their first list.
- **FR-002**: System MUST display all of a user's TODO lists on the listing screen, showing each list's name, color, icon (if set), and description, ordered by most recently created or updated first.
- **FR-003**: System MUST provide the ability to create a new list from both the blank slate screen and the listing screen, navigating to a dedicated full-page form.
- **FR-004**: System MUST require a list name when creating a new TODO list.
- **FR-005**: System MUST enforce unique list names per user account (case-insensitive).
- **FR-006**: System MUST provide a color selection when creating a list, with the first color pre-selected by default.
- **FR-007**: System MUST allow an optional icon selection when creating a list.
- **FR-008**: System MUST allow an optional description when creating a list.
- **FR-009**: System MUST provide four starting template options: Blank, Project, Weekly, and Shopping. Non-Blank templates pre-populate the list with named sections and starter items within each section.
- **FR-010**: System MUST pre-select the "Blank" template by default and require a template selection at all times (user cannot deselect all templates).
- **FR-011**: System MUST display a blank slate screen for a newly created or empty TODO list, prompting the user to add their first items.
- **FR-012**: System MUST show the list's name, color, and icon (if set) on the individual list view.
- **FR-013**: System MUST display appropriate validation errors inline when form submission fails.
- **FR-014**: System MUST allow users to edit an existing TODO list's name, color, icon, and description on a dedicated full-page form, with the same validation rules as creation.
- **FR-015**: System MUST NOT allow users to change the template of an existing TODO list.
- **FR-016**: System MUST allow users to delete a TODO list after confirming via a confirmation dialog.
- **FR-017**: System MUST permanently remove all sections and items belonging to a deleted TODO list.

- **FR-018**: System MUST require authentication for all TODO list actions. Unauthenticated users are redirected to sign-in.
- **FR-019**: System MUST scope all TODO list queries to the current authenticated user. A user MUST NOT be able to view, edit, update, or delete another user's lists.
- **FR-020**: System MUST return 404 Not Found (not 403 Forbidden) when a user attempts to access another user's list, to avoid revealing the existence of lists.
- **FR-021**: System MUST ignore any `user_id` parameter submitted during list creation. Lists are always created under the authenticated user's account.

### Key Entities

- **TODO List**: Represents a user's collection of items. Key attributes: name (required, unique per user), color (required), icon (optional), description (optional), template type (required, one of: Blank, Project, Weekly, Shopping). Belongs to a user. May contain sections and items pre-populated by the selected template.
- **Section**: A named grouping within a TODO list (e.g., "Monday", "Produce"). Used by non-Blank templates to organize items into categories. A TODO list has zero or more sections.
- **TODO Item**: An individual task or entry within a TODO list, optionally belonging to a section. Pre-populated by non-Blank templates with starter content.
- **User**: The authenticated owner of TODO lists. Has many TODO lists. Each user's list names are unique within their own account.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new TODO list in under 30 seconds from the listing or blank slate screen.
- **SC-002**: Users see the correct screen (blank slate vs. listing) within 1 second of navigating to the TODO Lists section.
- **SC-003**: 100% of validation errors (missing name, duplicate name, missing template) are communicated to the user before submission is accepted.
- **SC-004**: Users can identify each list by its name, color, and icon at a glance on the listing screen.
- **SC-005**: The default selections (Blank template, first color) allow users to create a list with minimal effort — only a name is required beyond defaults.

## Assumptions

- Color options are a predefined set of colors as defined in the visual reference `initial-screens.pen` (not a custom color picker).
- List name uniqueness is scoped per user (different users can have lists with the same name).
- Name uniqueness comparison is case-insensitive.
- The starting template pre-populates the list with sections and items but does not restrict future modifications. Users can add, remove, or rearrange sections and items after creation.
- Maximum list name length: 100 characters.
- Maximum description length: 500 characters.
- There is no limit on the number of TODO lists a user can create.
- The icon selection uses icons from the application's existing icon library (Font Awesome).
