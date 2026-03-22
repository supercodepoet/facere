# UI Contracts: TODO List Items Management

**Feature**: 003-todo-list-items | **Date**: 2026-03-21

## Routes

### TODO Items (nested under todo_lists)

```ruby
resources :todo_lists, path: "lists" do
  resources :todo_items, path: "items", except: [:index] do
    member do
      patch :toggle        # Toggle completion
      patch :archive       # Archive item
      patch :move          # Move to section/position
      post  :copy          # Copy to section
    end
    collection do
      patch :reorder       # Batch reorder positions
    end
  end

  resources :todo_sections, path: "sections", except: [:index, :show] do
    member do
      patch :archive       # Archive section + items
      patch :move          # Move section position
    end
    collection do
      patch :reorder       # Batch reorder section positions
    end
  end

  resources :checklist_items, path: "items/:todo_item_id/checklist", only: [:create, :update, :destroy] do
    member do
      patch :toggle        # Toggle checklist item completion
    end
  end

  resources :tags, path: "items/:todo_item_id/tags", only: [:create, :destroy]

  resources :attachments, path: "items/:todo_item_id/attachments", only: [:create, :destroy]
end
```

### Route Helpers (key routes)

| Helper | HTTP | Path | Controller#Action |
|--------|------|------|-------------------|
| `todo_list_todo_items_path(@list)` | POST | `/lists/:id/items` | `todo_items#create` |
| `todo_list_todo_item_path(@list, @item)` | GET | `/lists/:id/items/:item_id` | `todo_items#show` |
| `todo_list_todo_item_path(@list, @item)` | PATCH | `/lists/:id/items/:item_id` | `todo_items#update` |
| `todo_list_todo_item_path(@list, @item)` | DELETE | `/lists/:id/items/:item_id` | `todo_items#destroy` |
| `toggle_todo_list_todo_item_path(@list, @item)` | PATCH | `/lists/:id/items/:item_id/toggle` | `todo_items#toggle` |
| `archive_todo_list_todo_item_path(@list, @item)` | PATCH | `/lists/:id/items/:item_id/archive` | `todo_items#archive` |
| `move_todo_list_todo_item_path(@list, @item)` | PATCH | `/lists/:id/items/:item_id/move` | `todo_items#move` |
| `copy_todo_list_todo_item_path(@list, @item)` | POST | `/lists/:id/items/:item_id/copy` | `todo_items#copy` |
| `reorder_todo_list_todo_items_path(@list)` | PATCH | `/lists/:id/items/reorder` | `todo_items#reorder` |
| `todo_list_todo_sections_path(@list)` | POST | `/lists/:id/sections` | `todo_sections#create` |
| `todo_list_todo_section_path(@list, @section)` | PATCH | `/lists/:id/sections/:section_id` | `todo_sections#update` |
| `todo_list_todo_section_path(@list, @section)` | DELETE | `/lists/:id/sections/:section_id` | `todo_sections#destroy` |
| `archive_todo_list_todo_section_path(@list, @section)` | PATCH | `/lists/:id/sections/:section_id/archive` | `todo_sections#archive` |

## Views

### Updated Views

#### `app/views/todo_lists/show.html.erb`

Major overhaul. New structure:

```
show-layout
├── sidebar (existing partial, updated counts)
└── show-main
    ├── show-header
    │   ├── Back button + List emoji + Title + Edit pencil
    │   └── "Add Section" button + "Add Item" button (purple)
    ├── flash messages
    ├── empty-list-slate (when no items/sections)
    └── show-content
        ├── unsectioned-items
        │   ├── unsectioned-header ("Items without section")
        │   ├── _todo_item partial (for each item)
        │   └── _inline_item_input (when adding)
        ├── _section partial (for each section)
        │   ├── section-header (drag, chevron, icon, name, count, add item, ellipsis)
        │   ├── _todo_item partial (for each item in section)
        │   ├── _todo_item_completed partial (for completed items)
        │   ├── _empty_section (when section has no items)
        │   └── _inline_item_input (when adding within section)
        └── _inline_section_input (when adding section)
```

### New Views — List Detail

#### `app/views/todo_lists/_todo_item.html.erb`

Item row in list view.

```
todo-item (Turbo Frame: "todo_item_#{item.id}")
├── drag-handle (grip-vertical icon)
├── checkbox (ellipse, unchecked)
├── item-title (text, clickable → item detail)
├── due-badge (color-coded, optional)
├── avatar (initials, optional — self-assign)
└── priority-dot (colored dot, optional)
```

**Stimulus**: `data-controller="item-checkbox drag-reorder"`
**Turbo Frame**: `dom_id(item)`

#### `app/views/todo_lists/_todo_item_completed.html.erb`

Completed item variant (50% opacity, teal checkmark).

```
todo-item todo-item--completed (opacity: 0.5)
├── drag-handle
├── check-done (teal circle with white checkmark)
└── item-title (visually muted)
```

#### `app/views/todo_lists/_section.html.erb`

Section wrapper with header and items.

```
section-group (Turbo Frame: "section_#{section.id}")
├── section-header
│   ├── drag-handle (grip-vertical)
│   ├── collapse-chevron (chevron-down, rotates)
│   ├── section-icon (Font Awesome, colored)
│   ├── section-name (bold text)
│   ├── section-count (badge with item count)
│   ├── add-item-btn ("+ Add item")
│   └── section-more (ellipsis → wa-dropdown context menu)
├── section-items (collapsible container)
│   ├── _todo_item (for each active item)
│   ├── _todo_item_completed (for each completed item)
│   └── _empty_section (when no items)
└── _section_context_menu (wa-dropdown)
```

**Stimulus**: `data-controller="section-collapse drag-reorder context-menu"`

#### `app/views/todo_lists/_inline_item_input.html.erb`

Active input row for inline item creation.

```
active-input-row (purple border, shadow)
├── checkbox-placeholder (empty circle)
├── wa-input (text field, autofocus)
├── input-hints
│   ├── "Enter" badge + "to save"
│   └── "Esc" badge + "to cancel"
└── quick-actions-bar (below input)
    ├── Assign button (user-plus icon)
    ├── Due date button (calendar icon)
    └── Priority button (flag icon)
```

**Stimulus**: `data-controller="inline-item quick-actions"`

#### `app/views/todo_lists/_inline_section_input.html.erb`

Active input for section creation with icon picker.

```
active-section-input (purple border)
├── icon-picker-trigger (current icon + chevron → wa-dropdown)
├── wa-input (section name, autofocus)
├── input-hints ("Enter to create")
└── icon-dropdown (wa-dropdown with icon grid)
```

**Stimulus**: `data-controller="inline-section"`

#### `app/views/todo_lists/_item_context_menu.html.erb`

```html
<wa-dropdown placement="bottom-end">
  <wa-button slot="trigger" size="small" appearance="plain">
    <wa-icon name="ellipsis-vertical" variant="thin"></wa-icon>
  </wa-button>
  <wa-dropdown-item value="edit">Edit</wa-dropdown-item>
  <wa-dropdown-item value="move">Move...</wa-dropdown-item>
  <wa-dropdown-item value="copy">Copy...</wa-dropdown-item>
  <wa-divider></wa-divider>
  <wa-dropdown-item value="archive">Archive</wa-dropdown-item>
  <wa-dropdown-item value="delete" variant="danger">Delete</wa-dropdown-item>
  <wa-divider></wa-divider>
  <wa-dropdown-item value="insert">Insert a to-do</wa-dropdown-item>
</wa-dropdown>
```

#### `app/views/todo_lists/_section_context_menu.html.erb`

```html
<wa-dropdown placement="bottom-end">
  <wa-button slot="trigger" size="small" appearance="plain">
    <wa-icon name="ellipsis-vertical" variant="thin"></wa-icon>
  </wa-button>
  <wa-dropdown-item value="edit">Edit</wa-dropdown-item>
  <wa-dropdown-item value="move">Move...</wa-dropdown-item>
  <wa-dropdown-item value="copy">Copy...</wa-dropdown-item>
  <wa-divider></wa-divider>
  <wa-dropdown-item value="new_list">New list from group</wa-dropdown-item>
  <wa-divider></wa-divider>
  <wa-dropdown-item value="archive">Archive group</wa-dropdown-item>
  <wa-dropdown-item value="delete" variant="danger">Delete group</wa-dropdown-item>
  <wa-divider></wa-divider>
  <wa-dropdown-item value="insert">Insert a to-do</wa-dropdown-item>
</wa-dropdown>
```

### New Views — Item Detail

#### `app/views/todo_items/show.html.erb`

Two-column detail page.

```
show-layout
├── sidebar (same sidebar partial as list view)
└── show-main
    ├── top-bar
    │   ├── Back button + List emoji + Title + Edit pencil
    │   └── "Add Section" + "Add Item" buttons
    └── item-detail-content
        ├── left-column
        │   ├── item-header
        │   │   ├── status-row (status badge + priority badge)
        │   │   ├── item-title (h1, 28px bold)
        │   │   └── meta-row (created date + section name)
        │   ├── divider
        │   ├── _notes_section (Turbo Frame)
        │   ├── divider
        │   ├── _checklist_section (Turbo Frame)
        │   ├── divider
        │   ├── _attachments_section (Turbo Frame)
        │   ├── divider
        │   └── comments-section (single-user stub)
        └── right-column
            ├── _status_sidebar (status selector: Todo/In Progress/Done)
            ├── due-date-card
            ├── _tags_card
            └── actions-card (Mark Complete + Delete Item)
```

#### `app/views/todo_items/_notes_section.html.erb`

```
notes-section (Turbo Frame: "item_notes_#{item.id}")
├── notes-header
│   ├── notes-icon (file-text)
│   ├── "Notes" title
│   └── edit-btn (pencil icon)
├── notes-body (view mode: rendered rich text)
└── notes-edit (edit mode: ActionText/Trix editor, hidden by default)
```

**Stimulus**: `data-controller="notes-editor"`

#### `app/views/todo_items/_checklist_section.html.erb`

```
checklist-section (Turbo Frame: "item_checklist_#{item.id}")
├── checklist-header
│   ├── checklist-icon (square-check)
│   ├── "Checklist" title
│   ├── progress-badge ("3/5")
│   └── add-btn (+ icon)
└── checklist-items
    ├── checklist-item (for each: checkbox + name)
    └── checklist-input (when adding)
```

**Stimulus**: `data-controller="checklist"`

#### `app/views/todo_items/_attachments_section.html.erb`

```
attachments-section (Turbo Frame: "item_attachments_#{item.id}")
├── attachments-header
│   ├── attach-icon (paperclip)
│   ├── "Attachments" title
│   ├── count-badge
│   └── upload-btn (cloud-upload)
└── attach-grid (file cards, 3-column)
    └── file-card (file icon + name + size)
```

#### `app/views/todo_items/_status_sidebar.html.erb`

```
status-card
├── "Status" label
└── status-selector
    ├── Todo button (selectable)
    ├── In Progress button (selectable)
    └── Done button (selectable)
```

#### `app/views/todo_items/_tags_card.html.erb`

```
tags-card
├── "Tags" label
└── tags-row
    ├── tag-pill (for each: colored pill with name)
    └── add-tag-input (type to add)
```

## Stimulus Controllers

### `inline_item_controller.js`

**Targets**: `input`, `container`, `quickActions`
**Values**: `listId` (Number), `sectionId` (Number, optional)
**Actions**:
- `keydown→save` (Enter key): POST to create item, replace input via Turbo Stream
- `keydown→cancel` (Esc key): Remove input row, no server call
- `connect`: Auto-focus input

### `inline_section_controller.js`

**Targets**: `input`, `container`, `iconPicker`, `selectedIcon`
**Values**: `listId` (Number)
**Actions**:
- `keydown→save` (Enter key): POST to create section
- `keydown→cancel` (Esc key): Remove input row
- `selectIcon` (click on icon grid item): Set selected icon value
- `connect`: Auto-focus input

### `context_menu_controller.js`

**Targets**: `dropdown`
**Values**: `itemId` (Number), `sectionId` (Number), `listId` (Number)
**Actions**:
- `wa-select→dispatch`: Route selected action to appropriate handler
- `edit`: Toggle inline edit mode
- `move`: Open move dialog
- `copy`: Open copy dialog
- `archive`: PATCH archive endpoint
- `delete`: Open delete confirmation dialog
- `insertTodo`: Insert inline input at current position

### `drag_reorder_controller.js`

**Targets**: `item`, `dropZone`
**Values**: `url` (String, reorder endpoint)
**Actions**:
- `dragstart`: Add visual effects (rotation, shadow, tooltip)
- `dragover`: Show drop indicator
- `dragend`: Remove effects
- `drop`: Send PATCH with new position data

### `section_collapse_controller.js`

**Targets**: `items`, `chevron`
**Actions**:
- `toggle`: Slide items up/down, rotate chevron

### `item_checkbox_controller.js`

**Targets**: `checkbox`
**Values**: `url` (String, toggle endpoint)
**Actions**:
- `toggle`: PATCH toggle endpoint, Turbo Stream replaces item

### `notes_editor_controller.js`

**Targets**: `viewMode`, `editMode`, `form`
**Actions**:
- `edit`: Show Trix editor, hide rendered view
- `save`: Submit form, Turbo Frame updates notes section
- `cancel`: Hide editor, show rendered view

### `checklist_controller.js`

**Targets**: `items`, `input`, `progress`
**Values**: `url` (String, checklist endpoint)
**Actions**:
- `add` (Enter): POST new checklist item
- `toggle` (click checkbox): PATCH toggle completion
- `remove` (click x): DELETE checklist item

### `tag_manager_controller.js`

**Targets**: `input`, `suggestions`, `tags`
**Values**: `url` (String, tags endpoint)
**Actions**:
- `add` (Enter): POST create tag association
- `remove` (click x): DELETE tag association
- `search` (input): Filter/autocomplete existing tags

### `quick_actions_controller.js`

**Targets**: `container`
**Actions**:
- `setDueDate`: Open date picker input
- `setPriority`: Open priority selector (wa-dropdown)
- `assign`: Set self as assignee (single-user stub)

## CSS Architecture

All new styles added to `app/assets/stylesheets/todo_lists.css` (extending the existing file).

### New CSS Sections

```css
/* ===== TODO Item Rows ===== */
.todo-item { ... }              /* Item row in list view */
.todo-item--completed { ... }   /* Completed variant */
.todo-item .drag-handle { ... } /* Grip icon */
.todo-item .due-badge { ... }   /* Color-coded due date */
.todo-item .priority-dot { ... } /* Colored priority indicator */

/* ===== Section Headers ===== */
.section-header { ... }         /* Section header bar */
.section-items { ... }          /* Collapsible item container */
.section-items--collapsed { ... } /* Hidden state */

/* ===== Inline Creation ===== */
.active-input-row { ... }       /* Purple-bordered input */
.quick-actions-bar { ... }      /* Assign/Due/Priority buttons */

/* ===== Context Menus ===== */
/* Uses wa-dropdown styling — minimal custom CSS needed */

/* ===== Drag and Drop ===== */
.todo-item--dragging { ... }    /* Lift effect */
.drop-indicator { ... }         /* Insertion line */
.drag-hint { ... }              /* Tooltip */

/* ===== Item Detail Page ===== */
.item-detail-content { ... }    /* Two-column layout */
.item-detail-left { ... }       /* Content column */
.item-detail-right { ... }      /* Metadata sidebar */
.notes-section { ... }          /* Notes editor */
.checklist-section { ... }      /* Checklist items */
.attachments-section { ... }    /* File cards */
.status-card { ... }            /* Status selector */
.tags-card { ... }              /* Tag pills */

/* ===== Animations ===== */
@keyframes fadeSlideIn { ... }  /* New item appearance */
@keyframes checkPulse { ... }   /* Checkbox completion */
@keyframes dragLift { ... }     /* Drag start */
```
