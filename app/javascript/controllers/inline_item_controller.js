import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "quickActions"]

  connect() {
    this.inputTarget.focus()
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.element.requestSubmit()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    }
  }

  afterSubmit(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  cancel() {
    this.element.remove()
    const quickActions = document.querySelector('.quick-actions-bar')
    if (quickActions) quickActions.remove()
  }
}
