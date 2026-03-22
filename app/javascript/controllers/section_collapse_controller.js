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

  addItem(event) {
    if (this.itemsTarget.querySelector("#inline-item-input")) return

    const sectionId = event.currentTarget.dataset.sectionId
    const listId = event.currentTarget.dataset.listId
    const template = document.querySelector('[data-show-actions-target="itemTemplate"]')
    if (!template) return

    const clone = template.content.cloneNode(true)
    const form = clone.querySelector("form") || clone.querySelector("[data-controller='inline-item']")
    if (form) {
      const sectionInput = form.querySelector("[name='todo_item[todo_section_id]']")
      if (sectionInput) sectionInput.value = sectionId
    }

    this.itemsTarget.prepend(clone)
  }
}
