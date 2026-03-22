import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "itemTemplate", "sectionTemplate"]

  addItem() {
    if (document.getElementById("inline-item-input")) return

    const template = this.itemTemplateTarget
    const clone = template.content.cloneNode(true)

    const content = this.hasContentTarget ? this.contentTarget : this.element
    content.prepend(clone)
  }

  addSection() {
    if (document.getElementById("inline-section-input")) return

    const template = this.sectionTemplateTarget
    const clone = template.content.cloneNode(true)

    const content = this.hasContentTarget ? this.contentTarget : this.element
    content.append(clone)
  }
}
