import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit() {
    this.displayTarget.style.display = "none"
    this.formTarget.style.display = "block"
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  save(event) {
    if (event.type === "keydown") event.preventDefault()

    const value = this.inputTarget.value.trim()
    if (value === "") {
      this.cancel()
      return
    }

    this.formTarget.requestSubmit()
  }

  cancel() {
    this.formTarget.style.display = "none"
    this.displayTarget.style.display = ""
  }
}
