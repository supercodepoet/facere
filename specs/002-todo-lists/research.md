# Research: TODO List Management

**Feature Branch**: `002-todo-lists`
**Date**: 2026-03-21

## R1: UI Components for TODO List UI

**Decision**: Use standard HTML elements styled with CSS, with Font Awesome Pro icons via `<i>` tags, for all UI elements. Use a custom modal dialog for the delete confirmation.

**Rationale**: Standard HTML elements (`<input>`, `<button>`, `<textarea>`, etc.) provide native form participation, accessibility, and Stimulus compatibility. The existing authentication screens demonstrate the styling patterns. Font Awesome Pro icons are loaded via CDN kit. The Create New List form's template picker and color swatches use Stimulus controllers for accessible selection behavior with custom visual styling.

**Alternatives considered**:
- Third-party component libraries: Rejected — standard HTML with CSS is simpler and more maintainable.

## R2: Turbo Integration for List CRUD Operations

**Decision**: Use Turbo Drive for full-page navigation (index → new → show → edit), Turbo Frames for the delete confirmation modal, and Turbo Streams for flash message delivery after create/update/delete actions.

**Rationale**: The spec calls for separate full-page forms for create/edit, which maps naturally to Turbo Drive navigation. The delete confirmation modal overlays the current page, making it a good candidate for a Turbo Frame or custom modal dialog controlled by Stimulus. After successful create/update/delete, Turbo Streams can deliver success toasts without full page reloads.

**Alternatives considered**:
- Full Turbo Frame for entire CRUD flow: Rejected — over-engineering for this feature; full pages are simpler and spec-compliant.
- SPA-style with JavaScript state: Rejected — violates Vanilla Rails First principle.

## R3: Template Seeding Strategy

**Decision**: Define template content as a Ruby data structure within the `TodoList` model (class method or constant). On creation, the model populates sections and items based on the selected template via an `after_create` callback or explicit method call in the controller.

**Rationale**: Template definitions are small, static data that don't warrant a separate database table or YAML files. Keeping them in the model follows Rails convention and the YAGNI principle. A simple hash-based structure (`TEMPLATES` constant) maps template names to their sections and items.

**Alternatives considered**:
- YAML/JSON seed files: Rejected — adds file I/O complexity for ~20 lines of static data.
- Database-stored templates: Rejected — over-engineering; templates are fixed and not user-editable.
- Service object: Considered but deferred — if template logic grows beyond ~30 lines, extract to a `ListTemplateApplier` service object.

## R4: Color Palette from Design Reference

**Decision**: Define a fixed set of 6 colors as extracted from the `initial-screens.pen` Create New List screen. Store colors as string identifiers (e.g., "purple", "blue", "teal", "green", "pink", "orange") with corresponding hex values defined in CSS custom properties and a Ruby constant for validation.

**Rationale**: The design shows 6 color swatches in the create form. Using string identifiers rather than raw hex values keeps the database clean and allows CSS-level theming. The first color ("purple") is the default per spec requirements.

**Alternatives considered**:
- Storing hex values directly: Rejected — harder to maintain consistency between CSS and Ruby.
- Custom color picker: Rejected — spec explicitly states predefined colors.

## R5: Icon Selection Approach

**Decision**: Provide a curated set of Font Awesome Pro icons relevant to TODO list themes (e.g., list, cart, briefcase, book, dumbbell, house, utensils, plane). The icon field stores the Font Awesome icon name string (e.g., "fa-solid fa-cart-shopping"). Display icons using `<i>` tags with Font Awesome classes.

**Rationale**: The design shows ~5 icon options plus an add button in the create form. Font Awesome Pro is loaded via CDN kit. Storing icon names as strings is simple and flexible.

**Alternatives considered**:
- Icon upload/custom images: Rejected — over-engineering for current requirements.
- Emoji picker: Rejected — doesn't match the design reference.

## R6: App Layout Strategy

**Decision**: Create a new `app/views/layouts/app.html.erb` layout for authenticated app screens (as opposed to the existing `authentication.html.erb` for auth screens). The app layout includes the top navigation bar (logo, search, notifications, user avatar) visible in all .pen screens. The sidebar (list navigation) is part of the TODO list detail views, not the layout.

**Rationale**: The .pen designs show a clear distinction between auth screens (branded split panel) and app screens (top nav bar + content area). The sidebar appears only on detail views and contains list-specific navigation, so it belongs in the view templates rather than the layout.

**Alternatives considered**:
- Single layout with conditionals: Rejected — violates separation of concerns.
- Sidebar in layout: Rejected — sidebar content is feature-specific (list names), not app-wide.

## R7: List Ordering Implementation

**Decision**: Order TODO lists by `updated_at DESC` (most recently updated first). The `updated_at` timestamp is automatically maintained by Rails on every save, and touching a list when its items change ensures the ordering stays current.

**Rationale**: Spec clarification confirmed "most recently created or updated first." Rails' built-in `updated_at` column handles this naturally with a simple `order(updated_at: :desc)` scope.

**Alternatives considered**:
- Separate `last_activity_at` column: Rejected — `updated_at` is sufficient for current needs.
- Manual position column: Rejected — spec doesn't require custom ordering.

## R8: Case-Insensitive Uniqueness Validation

**Decision**: Use Rails' `validates :name, uniqueness: { scope: :user_id, case_sensitive: false }` combined with a database index. For SQLite, `COLLATE NOCASE` on the name column ensures case-insensitive uniqueness at the database level.

**Rationale**: Spec requires case-insensitive uniqueness per user. Rails validation handles the application layer, and a database constraint provides a safety net against race conditions.

**Alternatives considered**:
- Downcase before save: Considered as supplementary — but the spec doesn't require stored names to be lowercase, only that comparison is case-insensitive.
- Application-only validation: Rejected — race conditions possible without database constraint.
