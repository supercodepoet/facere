import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "chevron"]

  toggle() {
    const items = this.itemsTarget
    const chevron = this.chevronTarget

    if (items.classList.contains("section-items--collapsed")) {
      items.classList.remove("section-items--collapsed")
      chevron.classList.remove("section-chevron--collapsed")
      items.style.maxHeight = items.scrollHeight + "px"
      setTimeout(() => { items.style.maxHeight = "none" }, 300)
    } else {
      items.style.maxHeight = items.scrollHeight + "px"
      requestAnimationFrame(() => {
        items.style.maxHeight = "0px"
        items.classList.add("section-items--collapsed")
        chevron.classList.add("section-chevron--collapsed")
      })
    }
  }
}
