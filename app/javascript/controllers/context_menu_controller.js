import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["archiveForm", "deleteForm"]
  static values = { sectionId: Number, listId: Number, itemId: Number }

  dispatch(event) {
    const action = event.detail.item.value

    switch (action) {
      case "delete":
        this.deleteFormTarget.requestSubmit()
        break
      case "archive":
        this.archiveFormTarget.requestSubmit()
        break
      case "edit":
        this.editSection()
        break
    }
  }

  editSection() {
    if (!this.hasSectionIdValue) return

    // Find the section header within the parent turbo-frame
    const sectionFrame = this.element.closest("turbo-frame")
    if (!sectionFrame) return

    const sectionHeader = sectionFrame.querySelector(".section-header")
    if (!sectionHeader) return

    const nameEl = sectionHeader.querySelector(".section-name")
    if (!nameEl) return

    const currentName = nameEl.textContent.trim()
    const iconEl = sectionHeader.querySelector(".section-icon")
    const currentIcon = iconEl ? iconEl.getAttribute("name") : ""

    // Replace the section name with an editable input
    const editContainer = document.createElement("div")
    editContainer.className = "section-edit-inline"
    editContainer.innerHTML = `
      <div class="section-edit-row">
        <wa-dropdown placement="bottom-start" class="section-edit-icon-dropdown">
          <button slot="trigger" type="button" class="section-icon-picker-btn">
            <wa-icon name="${currentIcon || 'folder'}" variant="thin" class="section-icon-picker-icon section-edit-icon-display"></wa-icon>
            <wa-icon name="chevron-down" variant="thin" class="section-icon-picker-chevron"></wa-icon>
          </button>
          <div class="section-icon-dropdown">
            <span class="section-icon-dropdown-label">Choose an icon</span>
            <div class="section-icon-grid">
              ${['cart-shopping','briefcase','house','heart','book-open','code','palette','wrench','star','bolt'].map(icon =>
                `<button type="button" class="section-icon-grid-btn ${icon === currentIcon ? 'section-icon-grid-btn--selected' : ''}" data-icon="${icon}">
                  <wa-icon name="${icon}" variant="thin"></wa-icon>
                </button>`
              ).join('')}
            </div>
          </div>
        </wa-dropdown>
        <input type="text" class="section-edit-input" value="${currentName}" autofocus>
        <div class="section-edit-actions">
          <button type="button" class="section-edit-save-btn">
            <wa-icon name="check" variant="thin"></wa-icon>
          </button>
          <button type="button" class="section-edit-cancel-btn">
            <wa-icon name="xmark" variant="thin"></wa-icon>
          </button>
        </div>
      </div>
    `

    // Hide the original header content (keep the header element)
    const originalContent = sectionHeader.innerHTML
    sectionHeader.innerHTML = ""
    sectionHeader.appendChild(editContainer)
    sectionHeader.classList.add("section-header--editing")

    const input = editContainer.querySelector(".section-edit-input")
    const iconDisplay = editContainer.querySelector(".section-edit-icon-display")
    let selectedIcon = currentIcon
    input.focus()
    input.select()

    // Icon selection
    editContainer.querySelectorAll(".section-icon-grid-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        selectedIcon = btn.dataset.icon
        iconDisplay.setAttribute("name", selectedIcon)
        editContainer.querySelectorAll(".section-icon-grid-btn").forEach(b =>
          b.classList.toggle("section-icon-grid-btn--selected", b.dataset.icon === selectedIcon)
        )
        const dropdown = editContainer.querySelector(".section-edit-icon-dropdown")
        if (dropdown) dropdown.open = false
      })
    })

    // Save on Enter or save button click
    const save = () => {
      const newName = input.value.trim()
      if (!newName) return cancel()

      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      const body = new FormData()
      body.append("todo_section[name]", newName)
      if (selectedIcon) body.append("todo_section[icon]", selectedIcon)

      fetch(`/lists/${this.listIdValue}/sections/${this.sectionIdValue}`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: body
      }).then(response => {
        if (response.ok) return response.text()
      }).then(html => {
        if (html) Turbo.renderStreamMessage(html)
      })
    }

    // Cancel — restore original header
    const cancel = () => {
      sectionHeader.innerHTML = originalContent
      sectionHeader.classList.remove("section-header--editing")
    }

    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") { e.preventDefault(); save() }
      if (e.key === "Escape") { e.preventDefault(); cancel() }
    })

    editContainer.querySelector(".section-edit-save-btn").addEventListener("click", save)
    editContainer.querySelector(".section-edit-cancel-btn").addEventListener("click", cancel)
  }
}
