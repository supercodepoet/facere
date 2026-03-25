import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "editorFrame",
    "popover",
    "searchInput",
    "tagRow",
    "listView",
    "createView",
    "editView",
    "colorField",
    "swatch",
    "customColorInput",
    "deleteModal"
  ]

  connect() {
    this.closeOnOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  // ── Editor Open/Close ──────────────────────────────────

  toggleEditor(event) {
    event.stopPropagation()
    if (this.hasPopoverTarget && this.popoverTarget.classList.contains("tag-editor-popover--open")) {
      this.closeEditor()
    } else {
      this.openEditor()
    }
  }

  openEditor() {
    const frame = this.editorFrameTarget

    // First load: set src to trigger Turbo Frame fetch, then show on load
    if (!frame.src && frame.dataset.src) {
      frame.src = frame.dataset.src
      frame.addEventListener("turbo:frame-load", () => {
        if (this.hasPopoverTarget) {
          this.popoverTarget.classList.add("tag-editor-popover--open")
        }
      }, { once: true })
    } else if (this.hasPopoverTarget) {
      // Already loaded: just toggle open
      this.popoverTarget.classList.add("tag-editor-popover--open")
    }

  }

  closeEditor() {
    if (this.hasPopoverTarget) {
      this.popoverTarget.classList.remove("tag-editor-popover--open")
    }
    this.closeAllEllipsis()
    this.resetView()
  }

  handleOutsideClick(event) {
    // Close ellipsis menus if clicking outside them
    if (!event.target.closest(".tag-editor-ellipsis-wrap")) {
      this.closeAllEllipsis()
    }
    if (!this.element.contains(event.target)) {
      this.closeEditor()
    }
  }

  // ── Search ─────────────────────────────────────────────

  search() {
    if (!this.hasSearchInputTarget) return
    const query = this.searchInputTarget.value.toLowerCase()

    this.tagRowTargets.forEach(row => {
      const name = (row.dataset.tagName || "").toLowerCase()
      row.style.display = name.includes(query) ? "" : "none"
    })
  }

  // ── Ellipsis Menus ──────────────────────────────────────

  toggleEllipsis(event) {
    event.stopPropagation()
    event.preventDefault()
    const btn = event.currentTarget
    const wrap = btn.closest(".tag-editor-ellipsis-wrap")
    const menu = wrap?.querySelector(".tag-editor-ellipsis-menu")
    if (!menu) return

    const isOpen = menu.classList.contains("tag-editor-ellipsis-menu--open")
    this.closeAllEllipsis()
    if (!isOpen) {
      const rect = btn.getBoundingClientRect()
      menu.style.top = `${rect.bottom + 4}px`
      menu.style.left = `${rect.right - 160}px`
      menu.classList.add("tag-editor-ellipsis-menu--open")
    }
  }

  closeAllEllipsis() {
    this.element.querySelectorAll(".tag-editor-ellipsis-menu--open").forEach(m => {
      m.classList.remove("tag-editor-ellipsis-menu--open")
    })
  }

  // ── View Transitions ───────────────────────────────────

  showList() {
    if (this.hasListViewTarget) this.listViewTarget.style.display = ""
    if (this.hasCreateViewTarget) this.createViewTarget.style.display = "none"
    if (this.hasEditViewTarget) this.editViewTarget.style.display = "none"
  }

  showCreate() {
    if (this.hasListViewTarget) this.listViewTarget.style.display = "none"
    if (this.hasCreateViewTarget) this.createViewTarget.style.display = ""
    if (this.hasEditViewTarget) this.editViewTarget.style.display = "none"
  }

  showEdit(event) {
    this.closeAllEllipsis()
    const { tagId, tagName, tagColor } = event.currentTarget.dataset
    const color = tagColor || "#8B5CF6"

    if (this.hasListViewTarget) this.listViewTarget.style.display = "none"
    if (this.hasCreateViewTarget) this.createViewTarget.style.display = "none"
    if (this.hasEditViewTarget) {
      this.editViewTarget.style.display = ""

      const nameInput = this.editViewTarget.querySelector("[name='tag[name]']")
      const colorField = this.editViewTarget.querySelector("[name='tag[color]']")
      const form = this.editViewTarget.querySelector("form")

      if (nameInput) nameInput.value = tagName || ""
      if (colorField) colorField.value = color
      if (form && tagId) {
        form.action = form.action.replace(/\/tags\/\d+/, `/tags/${tagId}`)
      }

      // Update preview pill
      const previewPill = this.editViewTarget.querySelector(".tag-form-preview-pill")
      if (previewPill) {
        previewPill.style.background = `${color}20`
        previewPill.style.color = color
      }
      const previewDot = this.editViewTarget.querySelector(".tag-form-preview-dot")
      if (previewDot) previewDot.style.background = color
      const previewName = this.editViewTarget.querySelector(".tag-form-preview-name")
      if (previewName) previewName.textContent = tagName || "Preview"

      // Update custom color input
      const customInput = this.editViewTarget.querySelector(".tag-form-color-input")
      if (customInput) customInput.value = color

      // Update delete link data
      const deleteLink = this.editViewTarget.querySelector(".tag-form-delete-link")
      if (deleteLink) {
        deleteLink.dataset.tagId = tagId
        deleteLink.dataset.tagName = tagName
        deleteLink.dataset.tagColor = color
      }

      this.highlightSwatch(color, this.editViewTarget)
    }
  }

  resetView() {
    this.showList()
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
      this.search()
    }
  }

  // ── Preview ─────────────────────────────────────────────

  updatePreview(event) {
    const container = event.currentTarget.closest(".tag-form")
    if (!container) return
    const previewName = container.querySelector(".tag-form-preview-name")
    if (previewName) {
      previewName.textContent = event.currentTarget.value || "Preview"
    }
  }

  // ── Color Picker ───────────────────────────────────────

  selectColor(event) {
    event.preventDefault()
    const color = event.currentTarget.dataset.color
    const container = event.currentTarget.closest(".tag-form")
    this.setColor(color, container)
  }

  customColorChange(event) {
    const color = event.currentTarget.value
    const container = event.currentTarget.closest(".tag-form")
    this.setColor(color, container)
  }

  setColor(color, container) {
    if (!container) return
    const hiddenField = container.querySelector("[name='tag[color]']")
    if (hiddenField) hiddenField.value = color

    // Update swatch selection
    this.highlightSwatch(color, container)

    // Update preview pill
    const previewPill = container.querySelector(".tag-form-preview-pill")
    if (previewPill) {
      previewPill.style.background = `${color}20`
      previewPill.style.color = color
    }
    const previewDot = container.querySelector(".tag-form-preview-dot")
    if (previewDot) previewDot.style.background = color

    // Update custom color input
    const customInput = container.querySelector(".tag-form-color-input")
    if (customInput) customInput.value = color
  }

  highlightSwatch(color, container) {
    if (!container) return
    const swatches = container.querySelectorAll(".tag-form-swatch")
    swatches.forEach(swatch => {
      if (swatch.dataset.color === color) {
        swatch.classList.add("tag-form-swatch--selected")
        swatch.style.outlineColor = color
      } else {
        swatch.classList.remove("tag-form-swatch--selected")
        swatch.style.outlineColor = ""
      }
    })
  }

  // ── Delete Modal ───────────────────────────────────────

  openDeleteModal(event) {
    event.preventDefault()
    event.stopPropagation()
    this.closeAllEllipsis()
    const { tagId, tagName, tagColor } = event.currentTarget.dataset

    if (!this.hasDeleteModalTarget) return
    const modal = this.deleteModalTarget

    const nameEl = modal.querySelector(".tag-delete-modal-name")
    const dotEl = modal.querySelector(".tag-delete-modal-dot")
    const tagEl = modal.querySelector(".tag-delete-modal-tag")
    const form = modal.querySelector("form")

    if (nameEl) nameEl.textContent = tagName || ""
    if (dotEl) dotEl.style.background = tagColor || "#8B5CF6"
    if (tagEl) {
      tagEl.style.background = `${tagColor || "#8B5CF6"}20`
      tagEl.style.color = tagColor || "#8B5CF6"
    }
    if (form && tagId) {
      form.action = form.action.replace(/\/tags\/\d+/, `/tags/${tagId}`)
    }

    modal.classList.add("delete-modal--open")
  }

  closeDeleteModal() {
    if (this.hasDeleteModalTarget) {
      this.deleteModalTarget.classList.remove("delete-modal--open")
    }
  }

  backdropCloseDeleteModal(event) {
    if (event.target === this.deleteModalTarget) {
      this.closeDeleteModal()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
