import { Controller } from "@hotwired/stimulus"

// Coluna de datas à esquerda: ao clicar, rola a lista de eventos até o primeiro item da data.
// Não filtra; também destaca a data visível enquanto a lista é rolada.
export default class extends Controller {
  static targets = ["lista", "data", "secao"]
  static classes = ["ativo"]

  connect() {
    this.marcar()
  }

  ir(event) {
    event.preventDefault()
    const alvo = this.secaoTargets.find((s) => s.dataset.data === event.currentTarget.dataset.data)
    if (!alvo) return
    const lista = this.listaTarget
    const top = alvo.getBoundingClientRect().top - lista.getBoundingClientRect().top + lista.scrollTop - 8
    lista.scrollTo({ top, behavior: "smooth" })
  }

  marcar() {
    const lista = this.listaTarget
    const limite = lista.getBoundingClientRect().top + 24
    let atual = this.secaoTargets[0]
    this.secaoTargets.forEach((s) => {
      if (s.getBoundingClientRect().top <= limite) atual = s
    })
    this.dataTargets.forEach((b) => {
      const ativo = atual && b.dataset.data === atual.dataset.data
      b.classList.toggle("bg-sky-600", ativo)
      b.classList.toggle("text-white", ativo)
      b.classList.toggle("bg-white", !ativo)
      b.classList.toggle("text-slate-700", !ativo)
      if (ativo) b.scrollIntoView({ block: "nearest" })
    })
  }
}
