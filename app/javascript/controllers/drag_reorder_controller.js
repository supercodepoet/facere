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

    // Create drag hint tooltip
    this.tooltip = document.createElement("div")
    this.tooltip.className = "drag-hint-tooltip"
    this.tooltip.textContent = "Drop to reorder"
    document.body.appendChild(this.tooltip)
  }

  disconnect() {
    if (this.tooltip) this.tooltip.remove()
  }

  onDragStart(event) {
    // Find the turbo-frame (the draggable element)
    const frame = event.target.closest("turbo-frame.todo-item-frame")
    if (!frame) return

    this.draggedEl = frame
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", frame.id)

    requestAnimationFrame(() => {
      frame.classList.add("todo-item--dragging")
    })

    // Show tooltip
    const rect = frame.getBoundingClientRect()
    this.tooltip.style.left = `${rect.left + rect.width / 2 - 60}px`
    this.tooltip.style.top = `${rect.bottom + 8}px`
    this.tooltip.classList.add("visible")
  }

  onDragEnd(event) {
    if (this.draggedEl) {
      this.draggedEl.classList.remove("todo-item--dragging")
      this.draggedEl = null
    }

    this.clearDropIndicators()
    this.tooltip.classList.remove("visible")
  }

  onDragOver(event) {
    if (!this.draggedEl) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    this.clearDropIndicators()

    // Find the drop target: another item frame, a section-items container, or the unsectioned area
    const targetFrame = event.target.closest("turbo-frame.todo-item-frame")
    const sectionItems = event.target.closest(".section-items")
    const unsectioned = event.target.closest(".unsectioned-items")

    if (targetFrame && targetFrame !== this.draggedEl) {
      // Dropping on another item — show indicator above or below based on mouse position
      const rect = targetFrame.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2

      if (event.clientY < midpoint) {
        targetFrame.classList.add("drag-over-above")
      } else {
        targetFrame.classList.add("drag-over-below")
      }
    } else if (sectionItems && sectionItems.querySelectorAll("turbo-frame.todo-item-frame").length === 0) {
      // Empty section — highlight the whole area
      sectionItems.classList.add("drag-over-section")
    } else if (unsectioned) {
      // Could be dropping at the end of the unsectioned area
      unsectioned.classList.add("drag-over-section")
    }
  }

  onDragLeave(event) {
    const target = event.target.closest("turbo-frame.todo-item-frame, .section-items, .unsectioned-items")
    if (target) {
      target.classList.remove("drag-over-above", "drag-over-below", "drag-over-section")
    }
  }

  onDrop(event) {
    event.preventDefault()
    if (!this.draggedEl) return

    const targetFrame = event.target.closest("turbo-frame.todo-item-frame")
    const sectionItems = event.target.closest(".section-items")
    const unsectioned = event.target.closest(".unsectioned-items")

    if (targetFrame && targetFrame !== this.draggedEl) {
      // Drop relative to another item
      const rect = targetFrame.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2

      if (event.clientY < midpoint) {
        targetFrame.before(this.draggedEl)
      } else {
        targetFrame.after(this.draggedEl)
      }
    } else if (sectionItems) {
      // Drop into a section (possibly empty)
      const emptyHint = sectionItems.querySelector(".empty-section-hint")
      if (emptyHint) emptyHint.remove()
      sectionItems.appendChild(this.draggedEl)
    } else if (unsectioned) {
      unsectioned.appendChild(this.draggedEl)
    } else {
      // No valid target
      this.clearDropIndicators()
      return
    }

    this.clearDropIndicators()
    this.persistOrder()
  }

  clearDropIndicators() {
    this.element.querySelectorAll(".drag-over-above, .drag-over-below, .drag-over-section").forEach(el => {
      el.classList.remove("drag-over-above", "drag-over-below", "drag-over-section")
    })
  }

  persistOrder() {
    // Collect all items grouped by their container (section or unsectioned)
    const items = []

    // Unsectioned items
    const unsectioned = this.element.querySelector(".unsectioned-items")
    if (unsectioned) {
      unsectioned.querySelectorAll("turbo-frame.todo-item-frame").forEach((frame, index) => {
        items.push({
          id: frame.dataset.itemId,
          position: index,
          section_id: null
        })
      })
    }

    // Section items
    this.element.querySelectorAll(".section-items").forEach(sectionContainer => {
      const sectionFrame = sectionContainer.closest("turbo-frame")
      if (!sectionFrame) return
      const sectionId = sectionFrame.id.replace("todo_section_", "")

      sectionContainer.querySelectorAll("turbo-frame.todo-item-frame").forEach((frame, index) => {
        items.push({
          id: frame.dataset.itemId,
          position: index,
          section_id: sectionId
        })
      })
    })

    if (items.length === 0) return

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ items: items })
    })
  }
}
