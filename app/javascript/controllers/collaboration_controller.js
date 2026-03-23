import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.classList.toggle("collab-panel-open")
  }

  close() {
    this.panelTarget.classList.remove("collab-panel-open")
  }
}
