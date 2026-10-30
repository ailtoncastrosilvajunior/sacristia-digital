import { Controller } from "@hotwired/stimulus"

// Mensagem flash (notice/alert) com botão para fechar.
// Fecha sozinha após `delay` ms (padrão: 5s).
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timer = window.setTimeout(() => this.close(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    clearTimeout(this.timer)
    this.element.classList.add("opacity-0", "translate-y-[-0.25rem]", "transition-all", "duration-300")
    window.setTimeout(() => this.element.remove(), 280)
  }
}
