import { Controller } from "@hotwired/stimulus"

// Feedback imediato na linha ao marcar pago; totais/resumo vêm do Turbo Stream (SQL agregado).
export default class extends Controller {
  static targets = ["checkbox"]

  syncFromCheckbox() {
    const pago = this.checkboxTarget.checked
    this.applyRowState(pago)
    this.checkboxTarget.form?.requestSubmit()
  }

  revertOnError(event) {
    if (event.detail.success) return

    this.checkboxTarget.checked = !this.checkboxTarget.checked
    this.applyRowState(this.checkboxTarget.checked)
  }

  applyRowState(pago) {
    this.element.classList.toggle("bg-emerald-50/35", pago)
    this.element.classList.toggle("hover:bg-stone-50/70", !pago)
  }
}
