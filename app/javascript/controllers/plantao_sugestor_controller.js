import { Controller } from "@hotwired/stimulus"

// Sugere o bloco de plantão da competência conforme a data escolhida.
export default class extends Controller {
  static values = { periodos: Array }
  static targets = ["dataInput", "periodoSelect"]

  connect() {
    if (this.hasDataInputTarget && this.hasPeriodoSelectTarget && this.dataInputTarget.value && !this.periodoSelectTarget.value) {
      this.sugerir()
    }
  }

  sugerir() {
    if (!this.hasDataInputTarget || !this.hasPeriodoSelectTarget) return
    const dateStr = this.dataInputTarget.value
    if (!dateStr) return
    const day = parseInt(dateStr.split("-")[2], 10)
    if (isNaN(day)) return
    const periodo = this.periodosValue.find(p => day >= p.dia_inicio && day <= p.dia_fim)
    this.periodoSelectTarget.value = periodo ? String(periodo.id) : ""
  }
}
