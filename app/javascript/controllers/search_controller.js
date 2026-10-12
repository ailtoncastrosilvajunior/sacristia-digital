import { Controller } from "@hotwired/stimulus"

// Busca rápida: envia o formulário automaticamente após parar de digitar
// e mantém o contador de filtros ativos atualizado.
export default class extends Controller {
  static targets = ["filter", "badge"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.updateBadge()
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  updateBadge() {
    if (!this.hasBadgeTarget) return
    const count = this.filterTargets.filter((el) => el.value !== "").length
    this.badgeTarget.textContent = count
    this.badgeTarget.classList.toggle("hidden", count === 0)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
