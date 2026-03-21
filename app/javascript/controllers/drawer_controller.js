import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]

  open() {
    if (this.hasPanelTarget) this.panelTarget.classList.remove("translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("invisible", "opacity-0", "pointer-events-none")
      this.overlayTarget.classList.add("visible", "opacity-100", "pointer-events-auto")
    }
    document.body.classList.add("overflow-hidden")
  }

  close() {
    if (this.hasPanelTarget) this.panelTarget.classList.add("translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("invisible", "opacity-0", "pointer-events-none")
      this.overlayTarget.classList.remove("visible", "opacity-100", "pointer-events-auto")
    }
    document.body.classList.remove("overflow-hidden")
  }

  toggle() {
    if (this.hasPanelTarget && this.panelTarget.classList.contains("translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  closeOverlay(event) {
    if (event.target === this.overlayTarget) this.close()
  }
}
