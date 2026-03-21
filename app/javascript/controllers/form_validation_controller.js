import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "passwordConfirmation", "email", "terms", "requirements", "name"]

  validatePassword() {
    if (!this.hasPasswordTarget) return
    const value = this.passwordTarget.value

    const checks = {
      length: value.length >= 8,
      uppercase: /[A-Z]/.test(value),
      lowercase: /[a-z]/.test(value),
      digit: /\d/.test(value),
      special: /[^a-zA-Z\d]/.test(value)
    }

    if (this.hasRequirementsTarget) {
      this.requirementsTarget.querySelectorAll("[data-req]").forEach(el => {
        const req = el.dataset.req
        el.classList.toggle("met", checks[req])
      })
    }

    if (this.hasPasswordConfirmationTarget && this.passwordConfirmationTarget.value) {
      this.validatePasswordConfirmation()
    }
  }

  validatePasswordConfirmation() {
    if (!this.hasPasswordTarget || !this.hasPasswordConfirmationTarget) return

    const match = this.passwordTarget.value === this.passwordConfirmationTarget.value
    const input = this.passwordConfirmationTarget

    if (input.value && !match) {
      input.setAttribute("help-text", "Passwords do not match")
      input.setAttribute("invalid", "")
    } else {
      input.removeAttribute("help-text")
      input.removeAttribute("invalid")
    }
  }

  validateEmail() {
    if (!this.hasEmailTarget) return
    const value = this.emailTarget.value
    const valid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)

    if (value && !valid) {
      this.emailTarget.setAttribute("help-text", "Please enter a valid email address")
      this.emailTarget.setAttribute("invalid", "")
    } else {
      this.emailTarget.removeAttribute("help-text")
      this.emailTarget.removeAttribute("invalid")
    }
  }

  clearError(event) {
    const input = event.target
    input.removeAttribute("help-text")
    input.removeAttribute("invalid")
  }

  validateForm(event) {
    if (this.hasTermsTarget && !this.termsTarget.checked) {
      event.preventDefault()
      this.termsTarget.setAttribute("invalid", "")
      this.termsTarget.setAttribute("help-text", "You must accept the Terms of Service and Privacy Policy")
    }
  }
}
