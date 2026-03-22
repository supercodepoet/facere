import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("dragstart", this.dragStart.bind(this))
    this.element.addEventListener("dragend", this.dragEnd.bind(this))
    this.element.addEventListener("dragover", this.dragOver.bind(this))
    this.element.addEventListener("drop", this.drop.bind(this))
    this.element.addEventListener("dragleave", this.dragLeave.bind(this))
  }

  dragStart(event) {
    const item = event.target.closest("[draggable]")
    if (!item) return

    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", item.id)

    requestAnimationFrame(() => {
      item.classList.add("todo-item--dragging")
    })
  }

  dragEnd(event) {
    const item = event.target.closest("[draggable]")
    if (!item) return

    item.classList.remove("todo-item--dragging")
    document.querySelectorAll(".drop-indicator").forEach(el => el.remove())
    document.querySelectorAll(".drag-over").forEach(el => el.classList.remove("drag-over"))
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest(".todo-item, .section-header")
    if (target) {
      document.querySelectorAll(".drag-over").forEach(el => el.classList.remove("drag-over"))
      target.classList.add("drag-over")
    }
  }

  dragLeave(event) {
    const target = event.target.closest(".todo-item, .section-header")
    if (target) {
      target.classList.remove("drag-over")
    }
  }

  drop(event) {
    event.preventDefault()
    const draggedId = event.dataTransfer.getData("text/plain")
    const draggedEl = document.getElementById(draggedId)
    const target = event.target.closest(".todo-item, .section-group")

    if (!draggedEl || !target || draggedEl === target) return

    // Determine new position
    const container = target.closest(".section-items, .unsectioned-items, .show-content")
    if (!container) return

    const items = [...container.querySelectorAll(".todo-item, .section-group")]
    const targetIndex = items.indexOf(target.closest(".todo-item") || target.closest(".section-group"))

    // Move DOM element
    if (target.closest(".todo-item")) {
      target.before(draggedEl)
    } else {
      target.after(draggedEl)
    }

    // Collect new order and send to server
    this.saveOrder(container)

    document.querySelectorAll(".drag-over").forEach(el => el.classList.remove("drag-over"))
  }

  saveOrder(container) {
    const items = [...container.querySelectorAll(":scope > .todo-item, :scope > [id^='todo_item_']")]
    const sectionEl = container.closest(".section-group")
    const sectionId = sectionEl ? sectionEl.id.replace("todo_section_", "") : null

    const orderData = items.map((el, index) => {
      const id = el.id.replace("todo_item_", "")
      return { id: id, position: index, section_id: sectionId }
    })

    if (orderData.length === 0) return

    const listId = window.location.pathname.match(/\/lists\/(\d+)/)?.[1]
    if (!listId) return

    fetch(`/lists/${listId}/items/reorder`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ items: orderData })
    })
  }
}
