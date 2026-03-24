# Research: Detail Screen Polish

**Feature**: 006-detail-screen-polish | **Date**: 2026-03-23

## 1. Notes Save Button Behavior

**Decision**: Replace the current auto-save/Done pattern with an explicit "Save" button that triggers a form submission to persist the note content.

**Rationale**: The user explicitly requested "Save" instead of "Done" to make the action clear. The design reference shows a purple branded "Save" button. The existing `notes-autosave` Stimulus controller already handles saving via fetch — the change is primarily to the button label, styling, and ensuring the display updates after save.

**Alternatives considered**:
- Keep auto-save and rename button to "Save": Would work but auto-save + explicit save is redundant. The explicit save gives users control.
- Auto-save only (no button): User explicitly wants a Save button per the design.

## 2. Context Menu Implementation Pattern

**Decision**: Use existing standard dropdown markup pattern per constitution rules. Both section and item context menus already exist as partials — they need content additions to match the design.

**Rationale**: The constitution mandates standard dropdown components for menus. The section context menu needs "New list from group" and "Insert a to-do" items added. The item context menu needs "Edit" for inline title editing.

**Alternatives considered**:
- Custom dropdown: Violates constitution (standard dropdown markup is mandated).
- Right-click native context menu: Not portable, doesn't match design.

## 3. Due Date Picker Component

**Decision**: Use the native HTML `<input type="date">` for the calendar picker. The design shows a calendar overlay — the native date input provides this on all modern browsers, or a Stimulus controller with a custom calendar can be used if needed.

**Rationale**: The simplest approach is the native date input which provides a calendar picker on all modern browsers. If the design requires a custom-styled calendar, a Stimulus controller wrapping a lightweight date picker can be used.

**Alternatives considered**:
- Third-party date picker library: Violates YAGNI and Library-First (native input works).
- Custom calendar from scratch: Over-engineering for a standard date selection.

## 4. File Attachment Display Cards

**Decision**: Use the existing `_attachments_section.html.erb` partial and enhance it to show file cards with filename, type icon, and file size per the design. Active Storage provides `blob.filename`, `blob.content_type`, and `blob.byte_size` for display.

**Rationale**: Active Storage is already configured and file uploads work. The polish is in the presentation — showing cards instead of a simple list. The `file_type_icon` and `file_type_color` methods already exist on the TodoItem model.

**Alternatives considered**:
- Thumbnail previews for images: Nice-to-have but not in the design reference. Can be added later.

## 5. Assignee/Notify Picker from Collaborator Pool

**Decision**: The pickers already exist from feature 005 (list-collaboration). The `_assignees_card.html.erb` shows list members with add/remove buttons. The `_notify_card.html.erb` needs the same treatment. Both use `todo_list.all_members` to get the picker options.

**Rationale**: Feature 005 already built the infrastructure. This polish ensures the pickers work correctly and match the design styling.

**Alternatives considered**: None — the infrastructure is in place.
