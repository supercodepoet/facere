import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["view", "editor", "editBtn"]

  enterEdit() {
    this.viewTarget.style.display = "none"
    this.editorTarget.style.display = ""
    this.editBtnTarget.style.display = "none"
  }

  save() {
    const autosaveController = this.application.getControllerForElementAndIdentifier(
      this.editorTarget, "notes-autosave"
    )
    if (autosaveController) {
      autosaveController.save()
    }
    setTimeout(() => window.location.reload(), 300)
  }

  cancel() {
    this.editorTarget.style.display = "none"
    this.viewTarget.style.display = ""
    this.editBtnTarget.style.display = ""
  }
}
