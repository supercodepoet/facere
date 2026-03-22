import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["archiveForm", "deleteForm"]

  dispatch(event) {
    const action = event.detail.item.value

    switch (action) {
      case "delete":
        this.deleteFormTarget.requestSubmit()
        break
      case "archive":
        this.archiveFormTarget.requestSubmit()
        break
    }
  }
}
