import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "quickActions"]
  static values = { listId: Number, sectionId: Number }

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
    body.append("todo_item[name]", name)
    if (this.hasSectionIdValue && this.sectionIdValue) {
      body.append("todo_item[todo_section_id]", this.sectionIdValue)
    }

    // Pick up optional quick action values
    const dueDate = this.element.querySelector('[name="todo_item[due_date]"]')
    if (dueDate && dueDate.value) {
      body.append("todo_item[due_date]", dueDate.value)
    }
    const priority = this.element.querySelector('[name="todo_item[priority]"]')
    if (priority && priority.value) {
      body.append("todo_item[priority]", priority.value)
    }

    fetch(`/lists/${this.listIdValue}/items`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: body
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
        // Reset input for next item
        this.inputTarget.value = ""
        this.inputTarget.focus()
      }
    })
  }

  cancel() {
    this.element.remove()
    const quickActions = document.querySelector('.quick-actions-bar')
    if (quickActions) quickActions.remove()
  }
}
