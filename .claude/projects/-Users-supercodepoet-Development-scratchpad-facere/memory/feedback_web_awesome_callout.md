---
name: No Web Awesome — standard HTML + Font Awesome only
description: Never use wa-* custom elements. Use standard HTML with Font Awesome fa-light icons, custom dropdown/modal Stimulus controllers.
type: feedback
---

NEVER use Web Awesome custom elements (`wa-icon`, `wa-button`, `wa-dropdown`, `wa-dialog`, `wa-input`, `wa-checkbox`, `wa-callout`). Use standard HTML elements instead.

**Why:** Web Awesome was removed in feature 007 because the kit script wasn't loaded consistently across layouts (missing from `app.html.erb`), causing icons/buttons to render empty. Standard HTML with Font Awesome is universally supported and easier to style.

**How to apply:**
- Icons: `<i class="fa-light fa-{name}"></i>` (default weight). Use `fa-solid` for emphasis only.
- Buttons: Standard `<button>` or `<a>` elements with existing CSS classes.
- Dropdowns: Use `dropdown_controller.js` with `.dropdown-wrap` > trigger + `.dropdown-menu`.
- Modals: Use `modal_controller.js` with `.delete-modal-overlay` > `.delete-modal-panel`.
- Dialogs: Do NOT use `<dialog>` or `wa-dialog`. Use the custom modal pattern.
