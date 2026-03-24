import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "iconInput", "iconDisplay", "iconDropdown"]
  static values = { listId: Number }

  connect() {
    this.inputTarget.focus()
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.save()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    }
  }

  save() {
    const name = this.inputTarget.value.trim()
    if (!name) return

    const body = new FormData()
    body.append("todo_section[name]", name)
    const icon = this.iconInputTarget.value
    if (icon) body.append("todo_section[icon]", icon)

    fetch(`/lists/${this.listIdValue}/sections`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: body
    }).then(response => {
      if (response.ok) return response.text()
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
      }
    })
  }

  selectIcon(event) {
    const iconName = event.currentTarget.dataset.icon
    this.iconInputTarget.value = iconName
    this.iconDisplayTarget.className = this.iconDisplayTarget.className.replace(/fa-[\w-]+$/, 'fa-' + iconName)

    // Highlight selected icon in grid
    this.element.querySelectorAll(".icon-picker-grid-btn").forEach(btn => {
      btn.classList.toggle("icon-picker-grid-btn--selected", btn.dataset.icon === iconName)
    })

    // Close the dropdown
    if (this.hasIconDropdownTarget) {
      this.iconDropdownTarget.querySelector('.dropdown-menu').classList.remove('dropdown-menu--open')
    }
  }

  cancel() {
    this.element.remove()
  }
}
