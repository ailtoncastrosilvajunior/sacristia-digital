import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["escalados", "form", "ministroCoordenadorId", "ministroAdoracaoId", "sacerdoteId", "sacerdoteEscalado", "busca", "listaDisponiveis", "buscaVazia", "listaSacerdotes", "botaoRecarregar"]
  static values = {
    ministrosData: String,
    sacerdotesData: String,
    url: String,
    // Exibe os botões Coord./Ador. (desative para seleção simples de ministros)
    roles: { type: Boolean, default: true },
    // Nome dos inputs hidden enviados no formulário
    fieldName: { type: String, default: "ministro_ids[]" }
  }

  connect() {
    this.dataById = {}
    try {
      const arr = JSON.parse(this.ministrosDataValue || "[]")
      arr.forEach(m => { this.dataById[m.id] = m })
    } catch (_) {}

    const ids = Array.from(this.escaladosTarget.querySelectorAll(":scope > div[data-ministro-id]")).map(el => parseInt(el.dataset.ministroId, 10))
    this.escaladosIds = ids.filter(id => !isNaN(id))
    this.coordenadorId = this.hasMinistroCoordenadorIdTarget && this.ministroCoordenadorIdTarget.value ? parseInt(this.ministroCoordenadorIdTarget.value, 10) : null
    this.adoracaoId = this.hasMinistroAdoracaoIdTarget && this.ministroAdoracaoIdTarget.value ? parseInt(this.ministroAdoracaoIdTarget.value, 10) : null
    this.sacerdoteDataById = {}
    try {
      const arr = JSON.parse(this.sacerdotesDataValue || "[]")
      arr.forEach(s => { this.sacerdoteDataById[s.id] = s })
    } catch (_) {}
    const sid = this.hasSacerdoteIdTarget ? this.sacerdoteIdTarget.value : null
    this.sacerdoteId = (sid && sid !== "none") ? parseInt(sid, 10) : null
    this.syncForm()
  }

  // Recarrega do servidor as listas de sacerdotes/ministros sem perder o que já foi montado na tela.
  async recarregar(e) {
    const botao = e.currentTarget
    const tipo = botao.dataset.tipo
    const icone = botao.querySelector("[data-icone]")
    botao.disabled = true
    icone?.classList.add("animate-spin")
    try {
      const resp = await fetch(this.urlValue, {
        headers: { Accept: "text/html", "Turbo-Frame": "evento_modal" },
        credentials: "same-origin"
      })
      if (!resp.ok) throw new Error(resp.status)
      const doc = new DOMParser().parseFromString(await resp.text(), "text/html")
      if (tipo === "ministros") this.atualizarMinistros(doc)
      else this.atualizarSacerdotes(doc)
    } catch (_) {
      botao.title = "Não foi possível recarregar. Tente novamente."
    } finally {
      botao.disabled = false
      icone?.classList.remove("animate-spin")
    }
  }

  sincronizarChips(container, doc, { seletor, existentes, chaveId, chaveJson, ignorar = [], manter = [], registrar }) {
    const servidor = Array.from(doc.querySelectorAll(seletor))
    const idsServidor = new Set(Array.from(doc.querySelectorAll(existentes)).map((el) => el.dataset[chaveId]))
    const locais = Array.from(container.querySelectorAll(`:scope > div[data-${chaveId.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase())}]`))
      .filter((el) => !ignorar.includes(el.dataset[chaveId]))
    const idsLocais = new Set(locais.map((el) => el.dataset[chaveId]))

    // Remove quem deixou de existir/ficou inativo (exceto o que está escalado na tela)
    locais.forEach((el) => {
      const id = el.dataset[chaveId]
      if (!idsServidor.has(id) && !manter.includes(id)) el.remove()
    })

    // Insere novos mantendo ordem alfabética
    servidor.forEach((el) => {
      const id = el.dataset[chaveId]
      if (idsLocais.has(id)) return
      const novo = document.importNode(el, true)
      try { registrar(JSON.parse(novo.dataset[chaveJson])) } catch (_) {}
      const nome = this.normalizar(novo.textContent)
      const itens = Array.from(container.querySelectorAll(`:scope > div[data-${chaveId.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase())}]`))
        .filter((x) => !ignorar.includes(x.dataset[chaveId]))
      const depois = itens.find((x) => this.normalizar(x.textContent) > nome)
      container.insertBefore(novo, depois || container.querySelector("p") || null)
    })
  }

  atualizarMinistros(doc) {
    const manter = this.escaladosIds.map(String)
    this.sincronizarChips(this.listaDisponiveisTarget, doc, {
      seletor: "[data-zone=disponiveis] [data-ministro-id]",
      existentes: "[data-zone=disponiveis] [data-ministro-id], [data-zone=escalados] [data-ministro-id]",
      chaveId: "ministroId", chaveJson: "ministroJson", manter,
      registrar: (m) => { this.dataById[m.id] = m }
    })
    if (this.hasBuscaTarget) this.buscar()
  }

  atualizarSacerdotes(doc) {
    const selecionado = this.sacerdoteId ? [String(this.sacerdoteId)] : []
    this.sincronizarChips(this.listaSacerdotesTarget, doc, {
      seletor: "[data-zone=sacerdotes_disponiveis] [data-sacerdote-id]:not([data-sacerdote-id=none])",
      existentes: "[data-zone=sacerdotes_disponiveis] [data-sacerdote-id], [data-zone=sacerdote_evento] [data-sacerdote-id]",
      chaveId: "sacerdoteId", chaveJson: "sacerdoteJson", ignorar: ["none"], manter: selecionado,
      registrar: (s) => { this.sacerdoteDataById[s.id] = s }
    })
  }

  normalizar(texto) {
    return (texto || "").toLowerCase().normalize("NFD").replace(/\p{Diacritic}/gu, "").trim()
  }

  itensDisponiveis() {
    return Array.from(this.listaDisponiveisTarget.querySelectorAll(":scope > div[data-ministro-id]"))
  }

  buscar() {
    const q = this.normalizar(this.buscaTarget.value)
    let visiveis = 0
    this.itensDisponiveis().forEach((el) => {
      const id = parseInt(el.dataset.ministroId, 10)
      const nome = this.normalizar(this.dataById[id]?.nome || el.textContent)
      const mostrar = !q || nome.includes(q)
      el.classList.toggle("hidden", !mostrar)
      if (mostrar) visiveis += 1
    })
    if (this.hasBuscaVaziaTarget) this.buscaVaziaTarget.classList.toggle("hidden", visiveis > 0 || this.itensDisponiveis().length === 0)
  }

  // Enter adiciona o primeiro resultado visível; Esc limpa a busca.
  buscaTecla(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      const primeiro = this.itensDisponiveis().find((el) => !el.classList.contains("hidden") && !this.escaladosIds.includes(parseInt(el.dataset.ministroId, 10)))
      if (primeiro) {
        this.addMinistro(primeiro.dataset.ministroId)
        this.buscaTarget.select()
      }
    } else if (e.key === "Escape" && this.buscaTarget.value) {
      e.preventDefault()
      e.stopPropagation()
      this.buscaTarget.value = ""
      this.buscar()
    }
  }

  addMinistro(ministroId) {
    const id = parseInt(ministroId, 10)
    if (!this.escaladosIds.includes(id)) {
      this.escaladosIds = [...this.escaladosIds, id]
      this.renderEscalados()
      this.syncForm()
    }
  }

  removeMinistro(ministroId) {
    const id = parseInt(ministroId, 10)
    this.escaladosIds = this.escaladosIds.filter(i => i !== id)
    if (this.coordenadorId === id) {
      this.coordenadorId = this.escaladosIds[0] || null
    }
    if (this.adoracaoId === id) {
      this.adoracaoId = null
    }
    this.renderEscalados()
    this.syncForm()
  }

  setCoordenador(ministroId) {
    const id = parseInt(ministroId, 10)
    if (!this.escaladosIds.includes(id)) return
    this.coordenadorId = this.coordenadorId === id ? null : id
    this.renderEscalados()
    this.syncForm()
  }

  setSacerdote(sacerdoteId) {
    const id = sacerdoteId === "none" || !sacerdoteId ? null : parseInt(sacerdoteId, 10)
    this.sacerdoteId = id
    this.renderSacerdote()
    this.syncForm()
  }

  renderSacerdote() {
    if (!this.hasSacerdoteEscaladoTarget) return
    if (this.sacerdoteId && this.sacerdoteDataById[this.sacerdoteId]) {
      const s = this.sacerdoteDataById[this.sacerdoteId]
      const nome = (s.nome || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
      this.sacerdoteEscaladoTarget.innerHTML = `
        <div data-sacerdote-id="${this.sacerdoteId}"
             class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-sky-200 bg-white shadow-md cursor-grab active:cursor-grabbing hover:border-sky-400 transition-all text-sm font-semibold text-stone-900"
             draggable="true" data-action="dragstart->escalar-ministros#sacerdoteDragStart dragend->escalar-ministros#sacerdoteDragEnd">
          <span class="text-sky-500"><svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8h16M4 16h16"/></svg></span>
          <span>${nome}</span>
        </div>
      `
    } else {
      this.sacerdoteEscaladoTarget.innerHTML = `<div class="flex flex-col items-center justify-center py-6 rounded-xl border border-dashed border-sky-300/60 bg-white/50 text-center">
          <p class="text-sm font-medium text-sky-900/80">Solte o sacerdote aqui</p>
          <p class="text-xs text-sky-700/70 mt-1">Área do evento</p>
        </div>`
    }
  }

  setAdoracao(ministroId) {
    const id = parseInt(ministroId, 10)
    if (!this.escaladosIds.includes(id)) return
    this.adoracaoId = this.adoracaoId === id ? null : id
    this.renderEscalados()
    this.syncForm()
  }

  renderEscalados() {
    const roles = this.rolesValue
    this.escaladosTarget.innerHTML = this.escaladosIds.map(id => {
      const m = this.dataById[id]
      if (!m) return ""
      const isCoord = roles && this.coordenadorId === id
      const isAdoracao = roles && this.adoracaoId === id
      const estrela = roles ? `
          <span class="shrink-0 ${isCoord ? "text-amber-500" : "text-stone-300"}" title="${isCoord ? "Coordenador" : ""}">
            <svg class="w-4 h-4 ${isCoord ? "fill-amber-500" : ""}" fill="${isCoord ? "currentColor" : "none"}" stroke="currentColor" viewBox="0 0 20 20" aria-hidden="true">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
            </svg>
          </span>` : ""
      const botoesRoles = roles ? `
            <button type="button" class="shrink-0 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide rounded-md ${isCoord ? "bg-amber-100 text-amber-900 ring-1 ring-amber-200/80" : "bg-stone-100 text-stone-600 hover:bg-amber-50 hover:text-amber-800 ring-1 ring-stone-200/80"} transition-colors"
                    data-action="click->escalar-ministros#setCoordenadorClick"
                    data-ministro-id="${id}"
                    title="${isCoord ? "Coordenador" : "Definir como coordenador"}">
              ${isCoord ? "★ Coord." : "Coord."}
            </button>
            <button type="button" class="shrink-0 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide rounded-md ${isAdoracao ? "bg-fuchsia-100 text-fuchsia-900 ring-1 ring-fuchsia-200/80" : "bg-stone-100 text-stone-600 hover:bg-fuchsia-50 hover:text-fuchsia-800 ring-1 ring-stone-200/80"} transition-colors"
                    data-action="click->escalar-ministros#setAdoracaoClick"
                    data-ministro-id="${id}"
                    title="${isAdoracao ? "Adoração" : "Definir adoração (opcional)"}">
              ${isAdoracao ? "♥ Ador." : "Ador."}
            </button>` : ""
      return `
        <div data-ministro-id="${id}" class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-sky-200/80 bg-white shadow-sm cursor-grab active:cursor-grabbing hover:border-sky-400 hover:shadow-md transition-all group"
             draggable="true"
             data-action="dragstart->escalar-ministros#dragStart dragend->escalar-ministros#dragEnd
                          dragover->escalar-ministros#dragOver drop->escalar-ministros#drop">${estrela}
          <span class="text-[13px] font-semibold flex-1 min-w-0 truncate ${isCoord ? "text-sky-800" : "text-stone-800"}">${m.nome}</span>
          <div class="flex items-center gap-1 shrink-0">${botoesRoles}
            <button type="button" class="shrink-0 p-1 rounded-md text-stone-400 hover:text-red-600 hover:bg-red-50 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity"
                    data-action="click->escalar-ministros#removeClick"
                    title="Remover">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
          </div>
        </div>
      `
    }).join("") || this.estadoVazioHtml()
  }

  estadoVazioHtml() {
    return `<div class="flex flex-col items-center justify-center py-10 rounded-xl border border-dashed border-sky-300/70 bg-white/60 text-center">
          <div class="h-10 w-10 rounded-full bg-sky-100 text-sky-600 flex items-center justify-center mb-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
          </div>
          <p class="text-sm font-medium text-sky-900/90">${this.escaladosTarget.dataset.vazioTitulo || "Arraste ministros para cá"}</p>
          <p class="text-xs text-sky-700/70 mt-1 max-w-[14rem]">${this.escaladosTarget.dataset.vazioTexto || ""}</p>
        </div>`
  }

  syncForm() {
    const container = this.hasFormTarget ? this.formTarget.querySelector("[data-ministro-ids-container]") : null
    if (container) {
      container.innerHTML = this.escaladosIds.map(id =>
        `<input type="hidden" name="${this.fieldNameValue}" value="${id}">`
      ).join("")
    }
    if (this.hasMinistroCoordenadorIdTarget) {
      this.ministroCoordenadorIdTarget.value = this.coordenadorId || ""
    }
    if (this.hasMinistroAdoracaoIdTarget) {
      this.ministroAdoracaoIdTarget.value = this.adoracaoId || ""
    }
    if (this.hasSacerdoteIdTarget) {
      this.sacerdoteIdTarget.value = this.sacerdoteId || ""
    }
  }

  dragStart(e) {
    if (e.target.closest("[data-sacerdote-id]")) return
    const id = e.target.closest("[data-ministro-id]")?.dataset?.ministroId
    const fromEscalados = e.target.closest("[data-zone=escalados]")
    e.dataTransfer.setData("text/plain", JSON.stringify({ type: "ministro", ministroId: id, fromEscalados: !!fromEscalados }))
    e.dataTransfer.effectAllowed = "move"
    e.target.classList.add("opacity-50")
  }

  dragEnd(e) {
    e.target.classList.remove("opacity-50")
  }

  dragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"
  }

  sacerdoteDragStart(e) {
    const id = e.target.closest("[data-sacerdote-id]")?.dataset?.sacerdoteId
    const fromEvento = e.target.closest("[data-zone=sacerdote_evento]")
    e.dataTransfer.setData("text/plain", JSON.stringify({ type: "sacerdote", sacerdoteId: id, fromEvento: !!fromEvento }))
    e.dataTransfer.effectAllowed = "move"
    e.target.classList.add("opacity-50")
  }

  sacerdoteDragEnd(e) {
    e.target.classList.remove("opacity-50")
  }

  drop(e) {
    e.preventDefault()
    e.stopPropagation()
    try {
      const data = e.dataTransfer.getData("text/plain")
      if (!data) return
      const parsed = JSON.parse(data)
      const zone = e.currentTarget?.dataset?.zone
      if (parsed.type === "sacerdote") {
        if (zone === "sacerdote_evento") {
          this.setSacerdote(parsed.sacerdoteId)
        } else if (zone === "sacerdotes_disponiveis" && parsed.fromEvento) {
          this.setSacerdote("none")
        }
      } else {
        const { ministroId, fromEscalados } = parsed
        if (zone === "escalados") {
          this.addMinistro(ministroId)
        } else if (zone === "disponiveis" && fromEscalados) {
          this.removeMinistro(ministroId)
        }
      }
    } catch (_) {}
  }

  setCoordenadorClick(e) {
    e.preventDefault()
    e.stopPropagation()
    const id = e.currentTarget.dataset.ministroId
    if (id) this.setCoordenador(id)
  }

  setAdoracaoClick(e) {
    e.preventDefault()
    e.stopPropagation()
    const id = e.currentTarget.dataset.ministroId
    if (id) this.setAdoracao(id)
  }

  removeClick(e) {
    e.preventDefault()
    e.stopPropagation()
    const el = e.target.closest("[data-ministro-id]")
    if (el) this.removeMinistro(el.dataset.ministroId)
  }
}
