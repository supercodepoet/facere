import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "toggle"]

  toggle() {
    const input = this.inputTarget
    const isPassword = input.type === "password"

    input.type = isPassword ? "text" : "password"

    if (this.hasToggleTarget) {
      this.toggleTarget.name = isPassword ? "eye" : "eye-slash"
    }
  }
}
