import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]

  show() {
    this.formTarget.style.display = "flex"
    this.inputTarget.focus()
  }

  hide() {
    this.inputTarget.value = ""
    this.formTarget.style.display = "none"
  }

  save(event) {
    event.preventDefault()
    const value = this.inputTarget.value.trim()
    if (value === "") {
      this.hide()
      return
    }
    this.formTarget.requestSubmit()
  }
}
