import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.draggedEl = null

    this.element.addEventListener("dragstart", this.onDragStart.bind(this))
    this.element.addEventListener("dragend", this.onDragEnd.bind(this))
    this.element.addEventListener("dragover", this.onDragOver.bind(this))
    this.element.addEventListener("dragleave", this.onDragLeave.bind(this))
    this.element.addEventListener("drop", this.onDrop.bind(this))
  }

  onDragStart(event) {
    const card = event.target.closest("[data-list-id]")
    if (!card) return

    this.draggedEl = card
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", card.dataset.listId)

    requestAnimationFrame(() => {
      card.classList.add("list-card--dragging")
    })
  }

  onDragEnd() {
    if (this.draggedEl) {
      this.draggedEl.classList.remove("list-card--dragging")
      this.draggedEl = null
    }
    this.clearDropIndicators()
  }

  onDragOver(event) {
    if (!this.draggedEl) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    this.clearDropIndicators()

    const target = event.target.closest("[data-list-id]")
    if (target && target !== this.draggedEl) {
      const rect = target.getBoundingClientRect()
      const midpoint = rect.left + rect.width / 2

      if (event.clientX < midpoint) {
        target.classList.add("list-card--drop-before")
      } else {
        target.classList.add("list-card--drop-after")
      }
    }
  }

  onDragLeave(event) {
    const target = event.target.closest("[data-list-id]")
    if (target) {
      target.classList.remove("list-card--drop-before", "list-card--drop-after")
    }
  }

  onDrop(event) {
    event.preventDefault()
    if (!this.draggedEl) return

    const target = event.target.closest("[data-list-id]")
    if (target && target !== this.draggedEl) {
      const rect = target.getBoundingClientRect()
      const midpoint = rect.left + rect.width / 2

      if (event.clientX < midpoint) {
        target.before(this.draggedEl)
      } else {
        target.after(this.draggedEl)
      }
    }

    this.clearDropIndicators()
    this.persistOrder()
  }

  clearDropIndicators() {
    this.element.querySelectorAll(".list-card--drop-before, .list-card--drop-after").forEach(el => {
      el.classList.remove("list-card--drop-before", "list-card--drop-after")
    })
  }

  persistOrder() {
    const lists = []
    this.element.querySelectorAll("[data-list-id]").forEach((card, index) => {
      lists.push({ id: card.dataset.listId, position: index })
    })

    if (lists.length === 0) return

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ lists })
    })
  }
}
