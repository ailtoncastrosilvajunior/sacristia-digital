import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item", "empty"]

  filter() {
    const query = (this.inputTarget.value || "").trim().toLowerCase().normalize("NFD").replace(/\p{Diacritic}/gu, "")
    this.itemTargets.forEach((el) => {
      const nome = (el.dataset.nome || "").normalize("NFD").replace(/\p{Diacritic}/gu, "")
      const visible = !query || nome.includes(query)
      el.classList.toggle("hidden", !visible)
    })
    if (this.hasEmptyTarget) {
      const anyVisible = this.itemTargets.some((el) => !el.classList.contains("hidden"))
      this.emptyTarget.classList.toggle("hidden", anyVisible)
    }
  }
}
