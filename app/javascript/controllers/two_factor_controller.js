import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["codeInput", "codes"]

  checkCode() {
    if (!this.hasCodeInputTarget) return

    const value = this.codeInputTarget.value
    if (value && value.length === 6 && /^\d{6}$/.test(value)) {
      this.element.querySelector("form")?.requestSubmit()
    }
  }

  toggleRecovery(event) {
    event.preventDefault()
    if (!this.hasCodeInputTarget) return

    const input = this.codeInputTarget
    const isRecovery = input.getAttribute("label") === "Recovery Code"

    if (isRecovery) {
      input.setAttribute("label", "Verification Code")
      input.setAttribute("inputmode", "numeric")
      input.setAttribute("maxlength", "6")
      input.setAttribute("pattern", "[0-9]*")
    } else {
      input.setAttribute("label", "Recovery Code")
      input.removeAttribute("inputmode")
      input.setAttribute("maxlength", "10")
      input.removeAttribute("pattern")
    }
  }

  copyCodes() {
    if (!this.hasCodesTarget) return

    const codes = Array.from(this.codesTarget.querySelectorAll("div"))
      .map(el => el.textContent.trim())
      .join("\n")

    navigator.clipboard.writeText(codes).then(() => {
      const button = this.element.querySelector("[data-action*='copyCodes']")
      if (button) {
        const textNode = Array.from(button.childNodes).find(
          node => node.nodeType === Node.TEXT_NODE && node.textContent.trim()
        )
        const originalText = textNode ? textNode.textContent : button.textContent

        if (textNode) {
          textNode.textContent = " Copied!"
        } else {
          button.setAttribute("aria-label", "Copied!")
        }

        setTimeout(() => {
          if (textNode) {
            textNode.textContent = originalText
          } else {
            button.removeAttribute("aria-label")
          }
        }, 2000)
      }
    }).catch(error => {
      console.error("Failed to copy recovery codes:", error)
    })
  }
}
