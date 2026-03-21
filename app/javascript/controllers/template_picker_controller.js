import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  select(event) {
    if (event.currentTarget.disabled) return

    const template = event.currentTarget.dataset.template
    this.inputTarget.value = template

    this.element.querySelectorAll(".template-card").forEach(card => {
      card.classList.toggle("active", card.dataset.template === template)
    })
  }
}
