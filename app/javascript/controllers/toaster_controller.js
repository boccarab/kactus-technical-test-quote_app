import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 5_000 } }

  connect() {
    this.timeout = window.setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    window.clearTimeout(this.timeout)
  }

  dismiss() {
    window.clearTimeout(this.timeout)
    this.element.classList.add("translate-x-4", "opacity-0")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
