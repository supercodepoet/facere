import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["view", "editor", "editBtn"]

  toggle() {
    const editing = this.editorTarget.style.display !== "none"
    if (editing) {
      this.editorTarget.style.display = "none"
      this.viewTarget.style.display = ""
      this.editBtnTarget.innerHTML = '<wa-icon name="pen" variant="thin" style="font-size: 14px;"></wa-icon> Edit'
    } else {
      this.viewTarget.style.display = "none"
      this.editorTarget.style.display = ""
      this.editBtnTarget.innerHTML = '<wa-icon name="check" variant="thin" style="font-size: 14px;"></wa-icon> Done'
    }
  }
}
