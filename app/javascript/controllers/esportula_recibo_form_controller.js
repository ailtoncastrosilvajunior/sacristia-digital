import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectedCount", "selectedTotal", "selectedPages"]

  connect() {
    this.updateTotals()
  }

  selectAll() {
    this.checkboxTargets.forEach((cb) => {
      cb.checked = true
    })
    this.updateTotals()
  }

  selectNone() {
    this.checkboxTargets.forEach((cb) => {
      cb.checked = false
    })
    this.updateTotals()
  }

  selectMissas() {
    this.checkboxTargets.forEach((cb) => {
      cb.checked = cb.dataset.missa === "1"
    })
    this.updateTotals()
  }

  updateTotals() {
    const checked = this.checkboxTargets.filter((cb) => cb.checked)
    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.textContent = String(checked.length)
    }
    if (this.hasSelectedTotalTarget) {
      const sum = checked.reduce((acc, cb) => acc + parseFloat(cb.dataset.valor || "0"), 0)
      this.selectedTotalTarget.textContent = this.formatCurrency(sum)
    }
    if (this.hasSelectedPagesTarget) {
      this.selectedPagesTarget.textContent = String(checked.length)
    }
  }

  validateSubmit(event) {
    const any = this.checkboxTargets.some((cb) => cb.checked)
    if (!any) {
      event.preventDefault()
      window.alert("Marque ao menos uma espórtula para gerar o recibo.")
    }
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
  }
}
