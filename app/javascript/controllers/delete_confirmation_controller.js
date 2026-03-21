import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dialog: String }

  open() {
    const dialog = document.getElementById(this.dialogValue)
    if (dialog) dialog.show()
  }

  close() {
    const dialog = this.element.closest("wa-dialog") || document.querySelector("wa-dialog[open]")
    if (dialog) dialog.hide()
  }
}
