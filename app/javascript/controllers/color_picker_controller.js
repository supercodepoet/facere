import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  select(event) {
    const color = event.currentTarget.dataset.color
    this.inputTarget.value = color

    this.element.querySelectorAll(".color-swatch").forEach(swatch => {
      swatch.classList.toggle("active", swatch.dataset.color === color)
    })
  }
}
