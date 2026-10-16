import { Controller } from "@hotwired/stimulus"

// Mensagem flash (notice/alert) com botão para fechar.
// Fecha sozinha após `delay` ms (padrão: 60s).
export default class extends Controller {
  static values = { delay: { type: Number, default: 60000 } }

  connect() {
    this.timer = setTimeout(() => this.close(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    clearTimeout(this.timer)
    this.element.remove()
  }
}
