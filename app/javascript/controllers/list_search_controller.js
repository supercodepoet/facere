import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "item"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()

    this.itemTargets.forEach(item => {
      const text = item.textContent.toLowerCase()
      item.style.display = query === "" || text.includes(query) ? "" : "none"
    })
  }
}
