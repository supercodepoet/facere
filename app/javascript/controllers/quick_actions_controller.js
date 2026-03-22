import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dueDateInput", "priorityInput", "dueDateBtn", "priorityBtn"]

  setDueDate() {
    // Toggle date input visibility
    let input = this.element.querySelector('.quick-action-date-input')
    if (input) {
      input.remove()
      return
    }

    input = document.createElement('input')
    input.type = 'date'
    input.className = 'quick-action-date-input'
    input.addEventListener('change', (e) => {
      // Store due date for the inline item controller to pick up
      const inlineInput = document.querySelector('[data-controller="inline-item"]')
      if (inlineInput) {
        let hidden = inlineInput.querySelector('[name="todo_item[due_date]"]')
        if (!hidden) {
          hidden = document.createElement('input')
          hidden.type = 'hidden'
          hidden.name = 'todo_item[due_date]'
          inlineInput.appendChild(hidden)
        }
        hidden.value = e.target.value
      }
      input.remove()
    })
    this.element.appendChild(input)
    input.focus()
    if (typeof input.showPicker === 'function') {
      try { input.showPicker() } catch (e) { input.click() }
    } else {
      input.click()
    }
  }

  setPriority(event) {
    const priority = event.currentTarget.dataset.priority || 'none'
    const inlineInput = document.querySelector('[data-controller="inline-item"]')
    if (inlineInput) {
      let hidden = inlineInput.querySelector('[name="todo_item[priority]"]')
      if (!hidden) {
        hidden = document.createElement('input')
        hidden.type = 'hidden'
        hidden.name = 'todo_item[priority]'
        inlineInput.appendChild(hidden)
      }
      hidden.value = priority
    }
  }
}
