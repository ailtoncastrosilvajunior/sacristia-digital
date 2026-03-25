import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "frame"]

  show() {
    if (!this.hasFrameTarget) return
    if (!this.frameTarget.innerHTML.trim()) {
      this.close()
      return
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
      this.backdropTarget.classList.add("flex")
    }
  }

  close() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
      this.backdropTarget.classList.remove("flex")
    }
  }

  closeBackground(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
