import { Controller } from "@hotwired/stimulus"

// Seleciona uma competência (mostra só a lista correspondente) e revela as competências anteriores.
export default class extends Controller {
  static targets = ["tab", "painel", "extra", "maisBtn"]

  selecionar(event) {
    this.mostrar(event.currentTarget.dataset.competenciaId)
  }

  mostrar(id) {
    this.tabTargets.forEach((tab) => {
      const ativo = tab.dataset.competenciaId === id
      tab.setAttribute("aria-selected", ativo)
      tab.classList.toggle("bg-sky-600", ativo)
      tab.classList.toggle("text-white", ativo)
      tab.classList.toggle("bg-white", !ativo)
      tab.classList.toggle("text-stone-700", !ativo)
    })
    this.painelTargets.forEach((p) => p.classList.toggle("hidden", p.dataset.competenciaId !== id))
  }

  verMais() {
    this.extraTargets.forEach((el) => el.classList.remove("hidden"))
    this.maisBtnTarget.classList.add("hidden")
  }
}
