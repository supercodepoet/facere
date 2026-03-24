import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "emptyHint"]

  connect() {
    this.inputTarget.focus()
    this.hideHintIfItemsExist()
    // Re-check after DOM settles (template cloning timing)
    requestAnimationFrame(() => this.hideHintIfItemsExist())
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.element.querySelector("form").requestSubmit()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    }
  }

  afterSubmit(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
      this.hideHint()
    }
  }

  hideHintIfItemsExist() {
    const hasItems = document.querySelectorAll(".todo-item, .todo-item-frame").length > 0
    if (hasItems) this.hideHint()
  }

  hideHint() {
    if (this.hasEmptyHintTarget) {
      this.emptyHintTarget.style.display = "none"
      const divider = this.emptyHintTarget.previousElementSibling
      if (divider && divider.classList.contains("inline-divider")) {
        divider.style.display = "none"
      }
    }
  }

  cancel() {
    this.element.remove()
  }
}
