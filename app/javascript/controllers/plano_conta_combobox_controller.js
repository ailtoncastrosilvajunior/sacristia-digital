import { Controller } from "@hotwired/stimulus"
import { normalizeForSearch } from "utils/br_currency"

const MAX_RESULTS = 40

export default class extends Controller {
  static targets = ["input", "hidden", "list", "empty"]
  static values = {
    contas: { type: Array, default: [] },
    selectedId: { type: Number, default: 0 },
    selectedLabel: { type: String, default: "" },
  }

  connect() {
    if (this.selectedLabelValue) {
      this.inputTarget.value = this.selectedLabelValue
    } else if (this.selectedIdValue) {
      const conta = this.contasValue.find((c) => c.id === this.selectedIdValue)
      if (conta) this.inputTarget.value = conta.label
    }
    this.closeList()
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutside)
  }

  open() {
    this.renderList(this.inputTarget.value)
    this.listTarget.classList.remove("hidden")
    document.addEventListener("click", this.boundCloseOnOutside)
  }

  closeList() {
    this.listTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundCloseOnOutside)
  }

  boundCloseOnOutside = (event) => {
    if (!this.element.contains(event.target)) this.closeList()
  }

  onInput() {
    this.hiddenTarget.value = ""
    this.open()
  }

  onFocus() {
    this.open()
  }

  onKeydown(event) {
    if (event.key === "Escape") {
      this.closeList()
      this.inputTarget.blur()
      return
    }
    if (event.key === "ArrowDown" && this.listTarget.classList.contains("hidden")) {
      event.preventDefault()
      this.open()
    }
  }

  pick(event) {
    event.preventDefault()
    const li = event.target.closest("[data-id]")
    if (!li) return

    const id = Number(li.dataset.id)
    const conta = this.contasValue.find((c) => c.id === id)
    if (!conta) return

    this.hiddenTarget.value = String(conta.id)
    this.inputTarget.value = conta.label
    this.closeList()
    this.dispatch("picked", { bubbles: true })
  }

  renderList(query) {
    const ranked = this.rankContas(query).slice(0, MAX_RESULTS)

    if (ranked.length === 0) {
      this.listTarget.innerHTML = ""
      this.listTarget.classList.add("hidden")
      if (this.hasEmptyTarget) this.emptyTarget.classList.remove("hidden")
      return
    }

    if (this.hasEmptyTarget) this.emptyTarget.classList.add("hidden")
    this.listTarget.classList.remove("hidden")

    this.listTarget.innerHTML = ranked
      .map(
        (c) => `
        <li>
          <button type="button" data-id="${c.id}" data-action="plano-conta-combobox#pick"
            class="w-full text-left px-3 py-2 text-sm hover:bg-sky-50 focus:bg-sky-50 focus:outline-none">
            <span class="font-mono text-[11px] font-bold text-stone-500 mr-2">${this.escapeHtml(c.codigo)}</span>
            <span class="text-stone-800">${this.escapeHtml(c.nome)}</span>
          </button>
        </li>`
      )
      .join("")
  }

  rankContas(query) {
    const q = normalizeForSearch(query)
    const tokens = q.split(/\s+/).filter(Boolean)

    if (tokens.length === 0) return this.contasValue.slice(0, MAX_RESULTS)

    const scored = this.contasValue
      .map((conta) => {
        const codigo = normalizeForSearch(conta.codigo)
        const nome = normalizeForSearch(conta.nome)
        const label = normalizeForSearch(conta.label)
        let score = 0

        tokens.forEach((token) => {
          if (codigo === token) score += 100
          else if (codigo.startsWith(token)) score += 80
          else if (codigo.includes(token)) score += 50
          if (nome.startsWith(token)) score += 40
          else if (nome.includes(token)) score += 25
          if (label.includes(token)) score += 15
        })

        return { conta, score }
      })
      .filter((row) => row.score > 0)
      .sort((a, b) => b.score - a.score || a.conta.codigo.localeCompare(b.conta.codigo))

    return scored.map((row) => row.conta)
  }

  escapeHtml(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
