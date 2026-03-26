import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "emptySlate", "itemTemplate", "sectionTemplate"]

  addItem() {
    if (document.getElementById("inline-item-input")) return

    // Hide blank slate, show content area
    if (this.hasEmptySlateTarget) {
      this.emptySlateTarget.style.display = "none"
    }
    if (this.hasContentTarget) {
      this.contentTarget.style.display = ""
    }

    const template = this.itemTemplateTarget
    const clone = template.content.cloneNode(true)

    // Insert into the unsectioned items area, before the item list
    const itemList = document.getElementById("unsectioned-item-list")
    if (itemList) {
      itemList.prepend(clone)
    }
  }

  addSection() {
    if (document.getElementById("inline-section-input")) return

    // Hide blank slate, show content area
    if (this.hasEmptySlateTarget) {
      this.emptySlateTarget.style.display = "none"
    }
    if (this.hasContentTarget) {
      this.contentTarget.style.display = ""
    }

    const template = this.sectionTemplateTarget
    const clone = template.content.cloneNode(true)

    if (this.hasContentTarget) {
      this.contentTarget.append(clone)
    }
  }
}
