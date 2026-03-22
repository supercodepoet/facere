import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.timeout = null
    this.dirty = false
  }

  disconnect() {
    if (this.dirty) {
      this.save()
    }
    clearTimeout(this.timeout)
  }

  changed() {
    this.dirty = true
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.save(), 2000)
  }

  save() {
    if (!this.hasFormTarget) return

    this.dirty = false
    clearTimeout(this.timeout)

    const formData = new FormData(this.formTarget)
    fetch(this.formTarget.action, {
      method: "PATCH",
      body: formData,
      headers: {
        "Accept": "text/html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      }
    })
  }
}
