import { Controller } from "@hotwired/stimulus"

// Menu em <details>: fecha ao clicar fora, ao pressionar Esc ou ao navegar.
export default class extends Controller {
  connect() {
    this.onOutside = (e) => { if (!this.element.contains(e.target)) this.close() }
    this.onKey = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("click", this.onOutside)
    document.addEventListener("keydown", this.onKey)
    document.addEventListener("turbo:before-cache", this.onNavigate = () => this.close())
  }

  disconnect() {
    document.removeEventListener("click", this.onOutside)
    document.removeEventListener("keydown", this.onKey)
    document.removeEventListener("turbo:before-cache", this.onNavigate)
  }

  // clique em qualquer item do menu fecha
  closeOnItem(e) {
    if (e.target.closest("a, button")) this.close()
  }

  close() {
    this.element.removeAttribute("open")
  }
}
