import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { itemId: Number, sectionId: Number, listId: Number }

  dispatch(event) {
    const action = event.detail.item.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    switch (action) {
      case "delete":
        this.confirmDelete(csrfToken)
        break
      case "archive":
        this.archive(csrfToken)
        break
      case "edit":
        // Future: toggle inline edit
        break
      case "move":
      case "copy":
        // Future: open move/copy dialog
        break
      case "insert":
        // Future: insert inline input at position
        break
      case "new_list":
        // Future: create list from section
        break
    }
  }

  confirmDelete(csrfToken) {
    if (!confirm("Are you sure you want to delete this? This cannot be undone.")) return

    const url = this.hasItemIdValue
      ? `/lists/${this.listIdValue}/items/${this.itemIdValue}`
      : `/lists/${this.listIdValue}/sections/${this.sectionIdValue}`

    fetch(url, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }).then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
  }

  archive(csrfToken) {
    const url = this.hasItemIdValue
      ? `/lists/${this.listIdValue}/items/${this.itemIdValue}/archive`
      : `/lists/${this.listIdValue}/sections/${this.sectionIdValue}/archive`

    fetch(url, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }).then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
  }
}
