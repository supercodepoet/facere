import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "iconInput", "iconDisplay"]

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
      this.element.remove()
    }
  }

  selectIcon(event) {
    const iconName = event.currentTarget.dataset.icon
    this.iconInputTarget.value = iconName
    this.iconDisplayTarget.setAttribute("name", iconName)
  }

  cancel() {
    this.element.remove()
  }
}
