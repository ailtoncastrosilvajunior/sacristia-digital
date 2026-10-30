import { Controller } from "@hotwired/stimulus"

// Escala do mês: filtra os dias (todos / minha escala) e leva a lista até o dia escolhido.
// Celular: faixa fixa no topo + scroll só nos cards. Desktop: calendário lateral + scroll na lista.
export default class extends Controller {
  static targets = ["dia", "botao", "lista", "celula", "faixa", "faixaDia"]
  static values = { filtro: { type: String, default: "todos" } }

  connect() {
    this.aplicar()
    const navegadores = [...this.celulaTargets, ...this.faixaDiaTargets]
    if (navegadores.length === 0) return

    const hash = window.location.hash.match(/^#dia-(\d+)$/)
    const hoje = navegadores.find((el) => el.dataset.hoje === "true")
    const dia = hash ? hash[1] : hoje?.dataset.dia
    if (dia) {
      this.rolarPara(dia, "auto")
      this.destacarDia(dia)
      this.centralizarFaixa(dia, "auto")
    }
  }

  filtrar(event) {
    this.filtroValue = event.currentTarget.dataset.filtro
    this.aplicar()
    if (this.hasListaTarget) {
      this.listaTarget.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  irParaDia(event) {
    event.preventDefault()
    const link = event.currentTarget
    if (this.filtroValue !== "todos") {
      this.filtroValue = "todos"
      this.aplicar()
    }
    this.rolarPara(link.dataset.dia, "smooth")
    this.destacarDia(link.dataset.dia)
    this.centralizarFaixa(link.dataset.dia)
    history.replaceState(null, "", `#dia-${link.dataset.dia}`)
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

  rolarPara(dia, behavior) {
    const card = this.diaTargets.find((el) => el.dataset.dia === String(dia) && !el.classList.contains("hidden"))
    if (!card || !this.hasListaTarget) return

    this.listaTarget.scrollTo({ top: card.offsetTop, behavior })
  }

  destacarDia(dia) {
    const selRing = (el, sel) => {
      el.classList.toggle("ring-2", sel)
      el.classList.toggle("ring-sky-600", sel)
      el.classList.toggle("ring-offset-1", sel)
      el.classList.toggle("ring-offset-stone-50", sel)
      el.classList.toggle("shadow-md", sel)
      el.classList.toggle("z-[1]", sel)
    }
    this.celulaTargets.forEach((el) => selRing(el, el.dataset.dia === String(dia)))
    this.faixaDiaTargets.forEach((el) => selRing(el, el.dataset.dia === String(dia)))
  }

  centralizarFaixa(dia, behavior = "smooth") {
    if (!this.hasFaixaTarget) return
    const item = this.faixaDiaTargets.find((el) => el.dataset.dia === String(dia))
    if (!item) return
    const faixa = this.faixaTarget
    faixa.scrollTo({
      left: item.offsetLeft - (faixa.clientWidth - item.clientWidth) / 2,
      behavior,
    })
  }
}
