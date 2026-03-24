import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnOutsideClick = this.close.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains("dropdown-menu--open")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("dropdown-menu--open")
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  close() {
    this.menuTarget.classList.remove("dropdown-menu--open")
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    this.close()
    this.dispatch("select", { detail: { item: { value } } })
  }
}
