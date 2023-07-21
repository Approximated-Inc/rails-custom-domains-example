import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["alert"]

  dismiss(event) {
    event.preventDefault()
    this.alertTarget.parentElement.removeChild(this.alertTarget)
  }
}
