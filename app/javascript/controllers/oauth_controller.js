import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.handlePageShow = this.resetButtons.bind(this)
    window.addEventListener("pageshow", this.handlePageShow)
  }

  disconnect() {
    window.removeEventListener("pageshow", this.handlePageShow)
  }

  loading(event) {
    const button = event.currentTarget
    button.loading = true
    button.disabled = true
  }

  resetButtons() {
    this.buttonTargets.forEach(button => {
      button.loading = false
      button.disabled = false
    })
  }
}
