import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.classList.remove("delete-modal--open")
  }

  backdropClose(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
