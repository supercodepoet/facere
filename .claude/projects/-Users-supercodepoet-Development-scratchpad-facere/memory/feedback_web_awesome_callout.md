---
name: Web Awesome callout component
description: Use <wa-callout> not <wa-alert> for Web Awesome Pro alert/callout components
type: feedback
---

Use `<wa-callout>` instead of `<wa-alert>` for Web Awesome Pro notification/alert components.

**Why:** `<wa-alert>` is not a valid Web Awesome component. The correct component is `<wa-callout>`.

**How to apply:** Whenever generating Web Awesome Pro markup for alerts, warnings, error messages, or informational callouts, always use `<wa-callout>` with the appropriate `variant` attribute (success, danger, warning, primary).
