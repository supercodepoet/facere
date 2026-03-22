import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "iconInput", "iconDisplay"]
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

  selectIcon(event) {
    const iconName = event.currentTarget.dataset.icon
    this.iconInputTarget.value = iconName
    this.iconDisplayTarget.setAttribute("name", iconName)
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
        this.element.remove()
      }
    })
  }

  cancel() {
    this.element.remove()
  }
}
