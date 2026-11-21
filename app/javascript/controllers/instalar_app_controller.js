import { Controller } from "@hotwired/stimulus"

// Convite para instalar o app na tela inicial, com passo a passo (iPhone / Android).
// Some se o app já está instalado (modo standalone) e abre na aba do aparelho detectado.
export default class extends Controller {
  static targets = ["dialog", "aba", "painel", "cartao"]

  connect() {
    const instalado = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
    if (instalado) { this.element.remove(); return }
    this.cartaoTarget.classList.remove("hidden")
    this.selecionar(/android/i.test(navigator.userAgent) ? "android" : "ios")
  }

  abrir() { this.dialogTarget.showModal() }
  fechar() { this.dialogTarget.close() }
  backdrop(e) { if (e.target === this.dialogTarget) this.fechar() }

  trocar(e) { this.selecionar(e.currentTarget.dataset.plataforma) }

  selecionar(plataforma) {
    this.abaTargets.forEach((a) => {
      const ativa = a.dataset.plataforma === plataforma
      a.setAttribute("aria-selected", ativa)
      a.classList.toggle("bg-white", ativa)
      a.classList.toggle("shadow", ativa)
      a.classList.toggle("text-slate-900", ativa)
      a.classList.toggle("text-stone-500", !ativa)
    })
    this.painelTargets.forEach((p) => p.classList.toggle("hidden", p.dataset.plataforma !== plataforma))
  }
}
