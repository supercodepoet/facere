import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["viewMode", "editMode", "editBtn", "form"]

  toggleEdit() {
    const isEditing = this.editModeTarget.style.display !== "none"
    if (isEditing) {
      this.cancelEdit()
    } else {
      this.viewModeTarget.style.display = "none"
      this.editModeTarget.style.display = "block"
    }
  }

  cancelEdit() {
    this.editModeTarget.style.display = "none"
    this.viewModeTarget.style.display = "block"
  }
}
