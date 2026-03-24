---
name: Icon usage with Font Awesome Pro
description: Use standard <i> tags with Font Awesome classes for all icons
type: feedback
---

Use standard `<i>` tags with Font Awesome Pro classes for all icons (e.g. `<i class="fa-thin fa-icon-name"></i>`).

**Why:** The project uses Font Awesome Pro (CDN kit) for all iconography. Icons are rendered with standard HTML `<i>` elements and Font Awesome class names, not custom web components.

**How to apply:** Use `<i class="fa-{style} fa-{icon-name}"></i>` where `{style}` is one of `thin`, `light`, `regular`, `solid`, `duotone`, etc.
