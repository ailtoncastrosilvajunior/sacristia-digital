import { Controller } from "@hotwired/stimulus"

// Escala do mês: filtra os dias (todos / minha escala) e leva a lista até o dia escolhido.
// A lista do mês inteiro já vem na página; nada aqui consulta o servidor.
export default class extends Controller {
  static targets = ["dia", "botao", "faixa", "lista"]
  static values = { filtro: { type: String, default: "todos" } }

  connect() {
    this.aplicar()
    const hash = window.location.hash.match(/^#dia-(\d+)$/)
    const hoje = this.faixaTarget.querySelector("[data-hoje='true']")
    const dia = hash ? hash[1] : hoje?.dataset.dia
    if (dia) this.rolarPara(dia, "auto")
    this.centralizarNaFaixa(hoje)
  }

  filtrar(event) {
    this.filtroValue = event.currentTarget.dataset.filtro
    this.aplicar()
    this.listaTarget.scrollTo({ top: 0 })
  }

  irParaDia(event) {
    event.preventDefault()
    const link = event.currentTarget
    if (this.filtroValue !== "todos") {
      this.filtroValue = "todos"
      this.aplicar()
    }
    this.rolarPara(link.dataset.dia, "smooth")
    this.centralizarNaFaixa(link)
  }

  aplicar() {
    this.diaTargets.forEach((el) => {
      const mostra =
        this.filtroValue === "todos" ||
        (this.filtroValue === "meus" && el.dataset.meu === "true")
      el.classList.toggle("hidden", !mostra)
    })
    this.botaoTargets.forEach((botao) => {
      const ativo = botao.dataset.filtro === this.filtroValue
      botao.classList.toggle("bg-sky-600", ativo)
      botao.classList.toggle("text-white", ativo)
      botao.classList.toggle("bg-white", !ativo)
      botao.classList.toggle("text-slate-700", !ativo)
    })
  }

  // Posiciona o card do dia no topo da área rolável, à vista imediata.
  rolarPara(dia, behavior) {
    const card = this.diaTargets.find((el) => el.dataset.dia === String(dia))
    if (card) this.listaTarget.scrollTo({ top: card.offsetTop, behavior })
  }

  centralizarNaFaixa(item) {
    if (!item) return
    const faixa = this.faixaTarget
    faixa.scrollTo({ left: item.offsetLeft - (faixa.clientWidth - item.clientWidth) / 2, behavior: "smooth" })
  }
}
