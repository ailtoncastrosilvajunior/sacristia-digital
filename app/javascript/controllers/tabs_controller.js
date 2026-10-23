import { Controller } from "@hotwired/stimulus"

// Abas acessíveis: alterna painéis sem remover campos do DOM (formulários longos).
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: String }

  connect() {
    const initial = this.activeValue || this.tabTargets[0]?.dataset.tabsTabValue
    if (initial) this.show(initial, { focus: false })
  }

  select(event) {
    event.preventDefault()
    const id = event.currentTarget.dataset.tabsTabValue
    if (id) this.show(id)
  }

  show(id, { focus = true } = {}) {
    const pill = this.element.dataset.tabsStyle === "pill"

    this.tabTargets.forEach((tab) => {
      const on = tab.dataset.tabsTabValue === id
      tab.setAttribute("aria-selected", on ? "true" : "false")
      tab.tabIndex = on ? 0 : -1

      tab.classList.remove("bg-slate-800", "text-white", "shadow-sm", "bg-white", "bg-stone-100", "text-stone-700", "border", "border-stone-200", "hover:bg-stone-50", "hover:bg-stone-200")

      if (on) {
        tab.classList.add("bg-slate-800", "text-white", "shadow-sm")
      } else if (pill) {
        tab.classList.add("bg-stone-100", "text-stone-700", "hover:bg-stone-200")
      } else {
        tab.classList.add("bg-white", "text-stone-700", "border", "border-stone-200", "hover:bg-stone-50")
      }
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tabsPanelValue !== id
    })

    this.activeValue = id

    if (focus) {
      const tab = this.tabTargets.find((t) => t.dataset.tabsTabValue === id)
      tab?.focus({ preventScroll: true })
    }
  }
}
