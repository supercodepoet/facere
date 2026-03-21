import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  select(event) {
    const icon = event.currentTarget.dataset.icon
    const currentValue = this.inputTarget.value

    if (currentValue === icon) {
      this.inputTarget.value = ""
      event.currentTarget.classList.remove("active")
    } else {
      this.inputTarget.value = icon
      this.element.querySelectorAll(".icon-picker-btn[data-icon]").forEach(btn => {
        btn.classList.toggle("active", btn.dataset.icon === icon)
      })
    }
  }

  toggle() {
    // Placeholder for expanding icon grid
  }
}
