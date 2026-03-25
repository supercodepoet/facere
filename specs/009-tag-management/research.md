# Research: Tag Management

**Feature**: 009-tag-management
**Date**: 2026-03-24

## Existing Tag Infrastructure

### Decision: Build on existing Tag model and TagsController
**Rationale**: The Tag model (`belongs_to :user`, `has_many :todo_items through: :item_tags`) and TagsController already exist with basic create/destroy. Extending these is simpler and safer than rebuilding.
**Alternatives considered**: Creating a separate TagManagement controller — rejected because splitting concerns across controllers for the same resource adds confusion.

### Current State
- **Tag model**: name (unique per user, case-insensitive), color (optional hex), belongs_to :user
- **ItemTag model**: join table, validates uniqueness of tag_id per todo_item_id
- **TagsController**: create (find_or_create + attach) and destroy (remove from item) only, nested under `todo_list/todo_item/tags`
- **Routes**: `resources :tags, only: [:create, :destroy]` nested under todo_items
- **View**: Simple `_tags_card.html.erb` with inline add form and delete buttons — needs complete replacement

## Controller Design

### Decision: Expand TagsController with update action + add standalone tag management routes
**Rationale**: Need `update` for editing tags and a `destroy` action that permanently deletes the tag (vs current destroy which only removes from an item). Best approach: keep item-scoped toggle (add/remove) on TagsController, and add a separate set of routes for tag CRUD (edit, update, delete the tag itself).
**Alternatives considered**:
1. Single controller for everything — gets complex mixing item-tag associations with tag CRUD
2. Two controllers (TagsController for item-tag toggling, TagManagementController for CRUD) — cleaner separation but the routes pattern `todo_list/todo_item/tags` already exists

### Decision: Use Turbo Frames for all tag editor interactions
**Rationale**: The tag editor dropdown, create/edit forms, and delete confirmation are all inline UI within the detail view sidebar. Turbo Frames provide seamless partial updates without page reloads, consistent with the Hotwire-first constitution principle.
**Alternatives considered**: Stimulus-only with fetch — would work for simple toggles but adds complexity for form validation and error handling that Turbo handles natively.

## Search Implementation

### Decision: Client-side filtering via Stimulus controller
**Rationale**: Tag lists are per-user and small (typically <100 tags). Client-side filtering is instant and avoids server round-trips. All tags are rendered in the dropdown and filtered in JS by matching the search input against tag names.
**Alternatives considered**: Server-side search with Turbo Frame reload — adds latency for a small dataset, overly complex.

## Color Picker Design

### Decision: Preset swatches + native HTML color input for custom colors
**Rationale**: The design shows ~10 preset color circles plus a custom option. Using a native `<input type="color">` for custom colors provides a full-featured picker without any library dependency. Preset swatches are clickable divs that set a hidden field value.
**Alternatives considered**: Third-party color picker JS library — violates Library-First principle for a simple use case; the native picker is sufficient.

## Tag Editor UI Architecture

### Decision: Dropdown with nested views managed by Stimulus
**Rationale**: The tag editor has multiple "views" (tag list, create form, edit form, delete confirmation). Using a single Stimulus controller (`tag_editor_controller.js`) to manage view states (list → create → back to list, list → edit → back, etc.) keeps all logic co-located. Turbo Frames handle form submissions; Stimulus handles view transitions and search filtering.
**Alternatives considered**: Multiple Turbo Frames with server-rendered views — adds server round-trips for UI state changes that are purely client-side (opening create form doesn't need server data).

## Ellipsis Context Menu

### Decision: Reuse existing dropdown_controller.js pattern
**Rationale**: The project already has a dropdown Stimulus controller used throughout the app. Each tag row gets a nested dropdown for the ellipsis menu with "Edit Tag" and "Delete Tag" options.
**Alternatives considered**: Custom context menu controller — unnecessary duplication when dropdown_controller.js already handles open/close/outside-click.
