import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["viewMode", "editMode"]

  edit() {
    // Placeholder for toggling to Trix editor
    // Full implementation will use ActionText form
    console.log("Edit notes")
  }
}
