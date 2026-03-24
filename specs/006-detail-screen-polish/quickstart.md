# Quickstart: Detail Screen Polish

**Feature**: 006-detail-screen-polish | **Date**: 2026-03-23

## Prerequisites

- Ruby 4.0.1, Rails 8.1.2 (already installed)
- Feature 005 (list-collaboration) merged to main
- `bin/dev` running

## Setup

```bash
git checkout 006-detail-screen-polish
bin/dev
```

No migrations needed — this is view-layer only.

## Key Files to Modify

| File | What to Do |
|------|-----------|
| `_todo_item.html.erb` | Verify due date badge, priority dot, assignee avatars match design |
| `_todo_item_completed.html.erb` | Same for completed items |
| `_section_context_menu.html.erb` | Add "New list from group", "Insert a to-do" |
| `_item_context_menu.html.erb` | Verify all options match design |
| `_notes_section.html.erb` | Change button from "Done" to "Save", match button styling |
| `_assignees_card.html.erb` | Ensure picker shows all list members |
| `_due_date_card.html.erb` | Verify calendar picker works, add clear date option |
| `_notify_card.html.erb` | Picker shows all list members (same pattern as assignees) |
| `_attachments_section.html.erb` | File cards with filename, icon, size |
| `todo_lists.css` | Badge, pill, and card styling to match design |

## Visual Validation

Always compare changes against the .pen design screenshots:
- Open the .pen file in the editor
- Use `get_screenshot` on nodes `nGCDe` (list detail) and `sogSu` (item detail)
- Compare implementation against screenshots
