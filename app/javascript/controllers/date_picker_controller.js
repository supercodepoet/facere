import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]

  openPicker() {
    if (!this.hasInputTarget) return

    try {
      this.inputTarget.showPicker()
    } catch {
      this.inputTarget.click()
    }
  }

  submit() {
    if (!this.hasFormTarget) return

    this.formTarget.requestSubmit()
  }
}
