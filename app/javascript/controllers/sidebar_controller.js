import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    this.boundClose = this.close.bind(this)
    document.addEventListener("turbo:before-visit", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.boundClose)
  }

  toggle() {
    this.sidebarTarget.classList.toggle("-translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.toggle("invisible")
      this.overlayTarget.classList.toggle("opacity-0")
      this.overlayTarget.classList.toggle("pointer-events-none")
      document.body.classList.toggle("overflow-hidden")
    }
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("invisible", "opacity-0", "pointer-events-none")
      document.body.classList.remove("overflow-hidden")
    }
  }
}
