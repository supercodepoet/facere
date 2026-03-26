import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.draggedEl = null
    this.dropTarget = null

    this.boundDragStart = this.onDragStart.bind(this)
    this.boundDragEnd = this.onDragEnd.bind(this)
    this.boundDragOver = this.onDragOver.bind(this)
    this.boundDragLeave = this.onDragLeave.bind(this)
    this.boundDrop = this.onDrop.bind(this)

    this.element.addEventListener("dragstart", this.boundDragStart)
    this.element.addEventListener("dragend", this.boundDragEnd)
    this.element.addEventListener("dragover", this.boundDragOver)
    this.element.addEventListener("dragleave", this.boundDragLeave)
    this.element.addEventListener("drop", this.boundDrop)
  }

  disconnect() {
    this.element.removeEventListener("dragstart", this.boundDragStart)
    this.element.removeEventListener("dragend", this.boundDragEnd)
    this.element.removeEventListener("dragover", this.boundDragOver)
    this.element.removeEventListener("dragleave", this.boundDragLeave)
    this.element.removeEventListener("drop", this.boundDrop)
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
    this.clearDropTarget()
  }

  onDragOver(event) {
    if (!this.draggedEl) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest("[data-list-id]")
    const position = this.dropPosition(event, target)

    if (!position) {
      this.clearDropTarget()
      return
    }

    // Only update DOM if drop target or side changed
    if (this.dropTarget !== target || this.dropSide !== position) {
      this.clearDropTarget()
      this.dropTarget = target
      this.dropSide = position
      target.classList.add(position === "before" ? "list-card--drop-before" : "list-card--drop-after")
    }
  }

  onDragLeave(event) {
    const target = event.target.closest("[data-list-id]")
    if (target === this.dropTarget) {
      this.clearDropTarget()
    }
  }

  onDrop(event) {
    event.preventDefault()
    if (!this.draggedEl) return

    const target = event.target.closest("[data-list-id]")
    const position = this.dropPosition(event, target)

    if (position === "before") {
      target.before(this.draggedEl)
    } else if (position === "after") {
      target.after(this.draggedEl)
    }

    this.clearDropTarget()
    this.persistOrder()
  }

  dropPosition(event, target) {
    if (!target || target === this.draggedEl) return null

    const rect = target.getBoundingClientRect()
    return event.clientX < rect.left + rect.width / 2 ? "before" : "after"
  }

  clearDropTarget() {
    if (this.dropTarget) {
      this.dropTarget.classList.remove("list-card--drop-before", "list-card--drop-after")
      this.dropTarget = null
      this.dropSide = null
    }
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
