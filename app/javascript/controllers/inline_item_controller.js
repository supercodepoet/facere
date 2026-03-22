import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

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
    const wrapper = this.element.closest(".inline-item-wrapper")
    if (wrapper) {
      wrapper.remove()
    } else {
      this.element.remove()
    }
  }
}
