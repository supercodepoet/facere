# UI Contracts: TODO List Management

**Feature Branch**: `002-todo-lists`
**Date**: 2026-03-21

## Routes & Controller Actions

| Route                      | Method | Controller#Action        | View                      | Purpose                       |
|----------------------------|--------|--------------------------|---------------------------|-------------------------------|
| `/lists`                   | GET    | `todo_lists#index`       | `todo_lists/index`        | Listing or blank slate        |
| `/lists/new`               | GET    | `todo_lists#new`         | `todo_lists/new`          | Create form (full page)       |
| `/lists`                   | POST   | `todo_lists#create`      | redirects to show         | Create list                   |
| `/lists/:id`               | GET    | `todo_lists#show`        | `todo_lists/show`         | Detail view or empty slate    |
| `/lists/:id/edit`          | GET    | `todo_lists#edit`        | `todo_lists/edit`         | Edit form (full page)         |
| `/lists/:id`               | PATCH  | `todo_lists#update`      | redirects to show         | Update list                   |
| `/lists/:id`               | DELETE | `todo_lists#destroy`     | redirects to index        | Delete list                   |

## View Templates

### `todo_lists/index.html.erb`
- **Blank slate** (no lists): Illustration, heading "Your lists are waiting!", CTA button "Create My First List", feature highlights
- **Listing** (has lists): Grid of list cards, each showing name, color bar, progress %, item count, last updated. "+ New List" button in header. "Create New List" placeholder card at end of grid.

### `todo_lists/new.html.erb`
- Full-page form within content area (no sidebar)
- Fields: List Name (`wa-input`), Icon picker (grid of `wa-icon` buttons), Color picker (swatches), Description (`wa-textarea`), Template picker (card grid with radio behavior)
- Actions: Cancel (link back), Create List (`wa-button` brand)
- Error state: Custom `.form-error-banner` (triangle-exclamation icon, #FEE2E2 bg, 16px radius) at top, field-level error styling (red border, #FEF2F2 bg + error message)

### `todo_lists/edit.html.erb`
- Same form as new, pre-populated with current values
- Template picker is visible but disabled/read-only
- Actions: Cancel, Save Changes

### `todo_lists/show.html.erb`
- **Sidebar**: List of user's TODO lists with colored dots, active list highlighted
- **Main area**:
  - Header: Back arrow, list name with edit icon, "Add Status" and "Add Item" buttons
  - If empty: "Your list is ready!" blank slate with "Add First Item" and "Add Section" buttons
  - If has items: Sections with items, checkboxes, due dates, priority badges

### `todo_lists/_form.html.erb` (shared partial)
- Shared form fields between new and edit views
- Accepts `todo_list` form object and `editing` boolean

### `todo_lists/_list_card.html.erb` (partial)
- Individual list card for the grid: name, color bar, completion %, item count, updated timestamp, overflow menu (...)

### `todo_lists/_sidebar.html.erb` (partial)
- Left sidebar with search input, "MY LISTS" header, list of links with colored dots, "+ New List" button at bottom

### `todo_lists/_delete_confirmation.html.erb` (partial)
- `wa-dialog` modal: trash icon, "Delete this list?" heading, warning text, Cancel and Delete buttons

## Stimulus Controllers

| Controller                  | Purpose                                                    |
|-----------------------------|------------------------------------------------------------|
| `color-picker-controller`   | Manages color swatch selection (highlight active, set hidden field) |
| `icon-picker-controller`    | Manages icon selection (highlight active, set hidden field, allow deselection) |
| `template-picker-controller`| Manages template card selection (highlight active, set hidden field, prevent deselection) |
| `delete-confirmation-controller` | Opens/closes `wa-dialog` for delete confirmation     |
| `list-search-controller`    | Filters sidebar list items by search input                 |

## Flash Message Patterns

| Action          | Type    | Message                                                    |
|-----------------|---------|------------------------------------------------------------|
| Create success  | notice  | "List created successfully! Time to get things done"       |
| Update success  | notice  | "List updated successfully"                                |
| Delete success  | notice  | "List deleted successfully"                                |
| Validation fail | alert   | "Oops! Please fix the issues below before creating your list" |

## CSS Files

| File                  | Purpose                                       |
|-----------------------|-----------------------------------------------|
| `todo_lists.css`      | All TODO list feature styles (cards, forms, blank slates, sidebar, detail views) |

## Authorization

- All `TodoListsController` actions require authentication (`before_action :require_authentication`)
- All actions scope queries to `Current.user.todo_lists` to ensure users can only access their own lists
- Layout: `app` (new authenticated app layout, not `authentication`)
