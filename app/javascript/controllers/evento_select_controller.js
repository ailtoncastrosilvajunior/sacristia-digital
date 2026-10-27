import { Controller } from "@hotwired/stimulus"

// Select de eventos do lançamento: inicia com o dia da data do lançamento (de hoje a hoje),
// recarrega ao mudar a data e permite buscar eventos de um período.
export default class extends Controller {
  static targets = ["data", "select", "periodo", "toggle", "de", "ate", "resumo", "diaSemana"]
  static values = { url: String }

  atualizarDiaSemana() {
    if (!this.hasDiaSemanaTarget) return
    const chip = this.diaSemanaTarget
    const valor = this.dataTarget.value
    if (!valor) {
      chip.classList.add("hidden")
      chip.classList.remove("inline-flex")
      return
    }
    const [a, m, d] = valor.split("-").map(Number)
    const data = new Date(a, m - 1, d)
    const nome = data.toLocaleDateString("pt-BR", { weekday: "long" })
    const abr = data.toLocaleDateString("pt-BR", { weekday: "short" }).replace(".", "")
    chip.querySelector("[data-role=nome]").textContent = nome.charAt(0).toUpperCase() + nome.slice(1)
    chip.querySelector("[data-role=abbr]").textContent = abr.toUpperCase()

    const tons = {
      0: ["bg-amber-50 ring-amber-200 text-amber-900", "bg-amber-500 text-white"],
      6: ["bg-indigo-50 ring-indigo-200 text-indigo-900", "bg-indigo-500 text-white"]
    }
    const padrao = ["bg-sky-50 ring-sky-200 text-sky-900", "bg-sky-600 text-white"]
    const todas = [...Object.values(tons), padrao]
    const [corChip, corAbr] = tons[data.getDay()] || padrao
    const abrEl = chip.querySelector("[data-role=abbr]")
    todas.forEach(([c, ab]) => {
      chip.classList.remove(...c.split(" "))
      abrEl.classList.remove(...ab.split(" "))
    })
    chip.classList.add(...corChip.split(" "))
    abrEl.classList.add(...corAbr.split(" "))
    chip.classList.remove("hidden")
    chip.classList.add("inline-flex")
  }

  buscarDia() {
    this.atualizarDiaSemana()
    const dia = this.dataTarget.value
    if (!dia) return
    this.definirPeriodo(dia, dia)
    this.carregar(dia, dia)
  }

  buscarPeriodo() {
    const de = this.deTarget.value
    if (!de) return
    const ate = this.ateTarget.value || de
    this.atualizarResumo(de, ate)
    this.carregar(de, ate)
  }

  preset(event) {
    const base = this.dataTarget.value
    if (!base) return
    const [a, m, d] = base.split("-").map(Number)
    let de = new Date(a, m - 1, d)
    let ate = new Date(a, m - 1, d)
    switch (event.currentTarget.dataset.preset) {
      case "semana":
        ate.setDate(ate.getDate() + 6)
        break
      case "mes":
        de = new Date(a, m - 1, 1)
        ate = new Date(a, m, 0)
        break
    }
    this.definirPeriodo(this.iso(de), this.iso(ate))
    this.buscarPeriodo()
  }

  togglePeriodo() {
    const abrir = this.periodoTarget.classList.contains("hidden")
    this.periodoTarget.classList.toggle("hidden", !abrir)
    this.toggleTarget.setAttribute("aria-expanded", String(abrir))
    this.toggleTarget.textContent = abrir ? "Fechar" : "Alterar período"
  }

  definirPeriodo(de, ate) {
    this.deTarget.value = de
    this.ateTarget.value = ate
    this.atualizarResumo(de, ate)
  }

  atualizarResumo(de, ate) {
    if (!this.hasResumoTarget) return
    this.resumoTarget.textContent = de === ate ? this.br(de) : `${this.br(de)} a ${this.br(ate)}`
  }

  async carregar(de, ate) {
    const select = this.selectTarget
    const atual = select.value
    const atualTexto = select.selectedOptions[0]?.textContent
    const params = new URLSearchParams({ de, ate, data: this.dataTarget.value })

    let grupos
    try {
      const resp = await fetch(`${this.urlValue}?${params}`, { headers: { Accept: "application/json" } })
      if (!resp.ok) return
      grupos = (await resp.json()).grupos
    } catch (_) {
      return
    }

    const vazio = select.querySelector("option[value='']")?.textContent || "—"
    select.replaceChildren(new Option(vazio, ""))

    let achouAtual = false
    grupos.forEach((g) => {
      const og = document.createElement("optgroup")
      og.label = g.label
      g.opcoes.forEach((o) => {
        og.appendChild(new Option(o.label, o.id))
        if (String(o.id) === atual) achouAtual = true
      })
      select.appendChild(og)
    })

    // Mantém a seleção atual, mesmo que ela esteja fora do período buscado.
    if (atual && !achouAtual) select.appendChild(new Option(atualTexto, atual))
    select.value = atual || ""
  }

  iso(d) {
    const p = (n) => String(n).padStart(2, "0")
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
  }

  br(iso) {
    const [a, m, d] = iso.split("-")
    return `${d}/${m}/${a}`
  }
}
