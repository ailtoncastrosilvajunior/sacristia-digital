import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { equipes: Array }
  static targets = ["dataInput", "equipeSelect"]

  connect() {
    if (this.hasDataInputTarget && this.hasEquipeSelectTarget && this.dataInputTarget.value) {
      this.sugerir()
    }
  }

  sugerir() {
    if (!this.hasDataInputTarget || !this.hasEquipeSelectTarget) return
    const dateStr = this.dataInputTarget.value
    if (!dateStr) return
    const day = parseInt(dateStr.split("-")[2], 10)
    if (isNaN(day)) return
    const equipe = this.equipesValue.find(e => day >= e.dia_inicio && day <= e.dia_fim)
    this.equipeSelectTarget.value = equipe ? String(equipe.id) : ""
  }
}
