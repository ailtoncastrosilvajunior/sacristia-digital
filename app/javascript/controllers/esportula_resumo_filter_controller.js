import { Controller } from "@hotwired/stimulus"

const fmt = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 })

function normalizeNome(text) {
  return (text || "")
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .toLowerCase()
    .trim()
}

function matchNome(nome, query) {
  if (!query) return true
  return normalizeNome(nome).includes(normalizeNome(query))
}

function matchHorario(horario, query) {
  const q = (query || "").trim().replace(/[^\d:]/g, "")
  if (!q) return true
  const h = (horario || "").trim()
  if (h.includes(q)) return true
  return h.replace(":", "").includes(q.replace(":", ""))
}

function aggregate(events) {
  let missas = 0
  let confissoes = 0
  let previsto = 0
  let realizado = 0
  for (const e of events) {
    if (e.missa) missas += 1
    if (e.confissao) confissoes += 1
    previsto += Number(e.previsto) || 0
    realizado += Number(e.realizado) || 0
  }
  return {
    missas,
    confissoes,
    total_servicos: events.length,
    previsto,
    realizado,
    saldo: previsto - realizado
  }
}

export default class extends Controller {
  static targets = [
    "nome",
    "horario",
    "horariosList",
    "row",
    "count",
    "empty",
    "footMissas",
    "footConfissoes",
    "footTotal",
    "footPrevisto",
    "footRealizado",
    "footSaldo",
    "clear"
  ]

  static values = { total: Number, horarios: Array }

  connect() {
    this.populateHorariosList()
    this.applyFilter()
    // Reaplica o filtro depois que um Turbo Stream atualiza linhas/rodapé (marcar pago).
    this._onStream = (event) => {
      const original = event.detail.render
      event.detail.render = (stream) => {
        original(stream)
        requestAnimationFrame(() => this.applyFilter())
      }
    }
    document.addEventListener("turbo:before-stream-render", this._onStream)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this._onStream)
  }

  filter() {
    this.applyFilter()
  }

  clear() {
    if (this.hasNomeTarget) this.nomeTarget.value = ""
    if (this.hasHorarioTarget) this.horarioTarget.value = ""
    this.applyFilter()
  }

  populateHorariosList() {
    if (!this.hasHorariosListTarget || !this.horariosValue?.length) return
    this.horariosListTarget.innerHTML = ""
    for (const h of this.horariosValue) {
      const opt = document.createElement("option")
      opt.value = h
      this.horariosListTarget.appendChild(opt)
    }
  }

  applyFilter() {
    const nomeQ = this.hasNomeTarget ? this.nomeTarget.value : ""
    const horaQ = this.hasHorarioTarget ? this.horarioTarget.value : ""
    const filtering = Boolean(nomeQ.trim() || horaQ.trim())

    if (!filtering) {
      this.rowTargets.forEach((row) => {
        row.classList.remove("hidden")
        try {
          const events = JSON.parse(row.dataset.eventos || "[]")
          this.paintRow(row, aggregate(events))
        } catch {
          /* mantém valores renderizados pelo servidor */
        }
      })
      this.resetFoot()
      if (this.hasCountTarget) {
        const total = this.totalValue || this.rowTargets.length
        this.countTarget.textContent = `${total} sacerdotes na competência`
      }
      if (this.hasEmptyTarget) this.emptyTarget.classList.add("hidden")
      this.syncClearButton(false)
      return
    }

    const foot = { missas: 0, confissoes: 0, total_servicos: 0, previsto: 0, realizado: 0, saldo: 0 }
    let visible = 0

    this.rowTargets.forEach((row) => {
      let events = []
      try {
        events = JSON.parse(row.dataset.eventos || "[]")
      } catch {
        events = []
      }
      const nome = row.dataset.nome || ""

      if (!matchNome(nome, nomeQ)) {
        row.classList.add("hidden")
        return
      }

      const subset = horaQ.trim() ? events.filter((e) => matchHorario(e.horario, horaQ)) : events
      if (horaQ.trim() && subset.length === 0) {
        row.classList.add("hidden")
        return
      }

      const stats = aggregate(subset)
      this.paintRow(row, stats)
      row.classList.remove("hidden")
      visible += 1

      foot.missas += stats.missas
      foot.confissoes += stats.confissoes
      foot.total_servicos += stats.total_servicos
      foot.previsto += stats.previsto
      foot.realizado += stats.realizado
      foot.saldo += stats.saldo
    })

    if (filtering) this.paintFoot(foot)
    else this.resetFoot()

    if (this.hasCountTarget) {
      const total = this.totalValue || this.rowTargets.length
      this.countTarget.textContent = filtering
        ? `${visible} de ${total} sacerdotes (filtro ativo)`
        : `${total} sacerdotes na competência`
    }

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible > 0 || this.rowTargets.length === 0)
    }

    this.syncClearButton(true)
  }

  syncClearButton(active) {
    if (!this.hasClearTarget) return
    this.clearTarget.classList.toggle("hidden", !active)
    this.clearTarget.classList.toggle("inline-flex", active)
  }

  paintRow(row, stats) {
    const quitado = stats.saldo === 0 && stats.previsto > 0
    const saldoCell = row.querySelector("[data-esportula-resumo-saldo]")
    if (saldoCell) {
      saldoCell.textContent = fmt.format(stats.saldo)
      saldoCell.classList.toggle("text-emerald-700", quitado)
      saldoCell.classList.toggle("text-indigo-800", !quitado)
    }
    this.setCountBadge(row.querySelector("[data-esportula-resumo-missas]"), stats.missas, "sky")
    this.setCountBadge(row.querySelector("[data-esportula-resumo-confissoes]"), stats.confissoes, "amber")
    const totalEl = row.querySelector("[data-esportula-resumo-total]")
    if (totalEl) totalEl.textContent = String(stats.total_servicos)
    const prev = row.querySelector("[data-esportula-resumo-previsto]")
    if (prev) prev.textContent = fmt.format(stats.previsto)
    const real = row.querySelector("[data-esportula-resumo-realizado]")
    if (real) real.textContent = fmt.format(stats.realizado)
  }

  setCountBadge(cell, count, tone) {
    if (!cell) return
    if (count > 0) {
      const cls =
        tone === "amber"
          ? "inline-flex min-w-[1.25rem] justify-center rounded-md bg-amber-100 px-1 py-0.5 text-[10px] font-bold tabular-nums text-amber-900 ring-1 ring-amber-200/80"
          : "inline-flex min-w-[1.25rem] justify-center rounded-md bg-sky-100 px-1 py-0.5 text-[10px] font-bold tabular-nums text-sky-800 ring-1 ring-sky-200/80"
      cell.innerHTML = `<span class="${cls}">${count}</span>`
    } else {
      cell.innerHTML = `<span class="text-slate-300 tabular-nums">·</span>`
    }
  }

  paintFoot(foot) {
    if (this.hasFootMissasTarget) this.footMissasTarget.textContent = String(foot.missas)
    if (this.hasFootConfissoesTarget) this.footConfissoesTarget.textContent = String(foot.confissoes)
    if (this.hasFootTotalTarget) this.footTotalTarget.textContent = String(foot.total_servicos)
    if (this.hasFootPrevistoTarget) this.footPrevistoTarget.textContent = fmt.format(foot.previsto)
    if (this.hasFootRealizadoTarget) this.footRealizadoTarget.textContent = fmt.format(foot.realizado)
    if (this.hasFootSaldoTarget) this.footSaldoTarget.textContent = fmt.format(foot.saldo)
  }

  resetFoot() {
    for (const el of [
      this.hasFootMissasTarget && this.footMissasTarget,
      this.hasFootConfissoesTarget && this.footConfissoesTarget,
      this.hasFootTotalTarget && this.footTotalTarget,
      this.hasFootPrevistoTarget && this.footPrevistoTarget,
      this.hasFootRealizadoTarget && this.footRealizadoTarget,
      this.hasFootSaldoTarget && this.footSaldoTarget
    ].filter(Boolean)) {
      if (el.dataset.initial != null) el.textContent = el.dataset.initial
    }
  }
}
