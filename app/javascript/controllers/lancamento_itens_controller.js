import { Controller } from "@hotwired/stimulus"
import { parseBrDecimal, formatBrMoney } from "utils/br_currency"

export default class extends Controller {
  static targets = ["item", "valorTotal", "valorTotalHidden"]

  connect() {
    this.element.addEventListener("money-input:changed", () => this.recalculate())
    // Aguarda os money-input dos itens conectarem antes de calcular (ex.: edit).
    requestAnimationFrame(() => requestAnimationFrame(() => this.recalculate()))
  }

  itemAdded() {
    this.recalculate()
  }

  itemRemoved() {
    this.recalculate()
  }

  recalculate() {
    let soma = 0

    this.itemTargets.forEach((row) => {
      if (row.classList.contains("hidden")) return

      const qtyEl = row.querySelector("[data-lancamento-item-qty]")
      const priceEl = row.querySelector("[data-lancamento-item-price]")
      const discountEl = row.querySelector("[data-lancamento-item-desconto]")
      const valorEl = row.querySelector("[data-lancamento-item-valor]")

      if (!qtyEl || !priceEl || !valorEl) return

      const qty = parseBrDecimal(qtyEl.value) ?? 0
      const price = parseBrDecimal(priceEl.value) ?? 0
      const discount = parseBrDecimal(discountEl?.value) ?? 0
      const bruto = Math.round(qty * price * 100) / 100
      const total = Math.max(0, Math.round((bruto - discount) * 100) / 100)

      this.setMoneyField(valorEl, total)
      soma += total
    })

    soma = Math.round(soma * 100) / 100
    if (this.hasValorTotalTarget) {
      this.valorTotalTarget.value = formatBrMoney(soma)
    }
    if (this.hasValorTotalHiddenTarget) {
      this.valorTotalHiddenTarget.value = soma.toFixed(2)
    }
  }

  setMoneyField(el, n) {
    el.dataset.rawValue = String(n)
    el.value = formatBrMoney(n)
  }

  beforeSubmit(event) {
    this.element.querySelectorAll('[data-controller~="money-input"]').forEach((wrapper) => {
      const controller = this.application.getControllerForElementAndIdentifier(wrapper, "money-input")
      controller?.beforeSubmit()
    })

    this.itemTargets.forEach((row) => {
      if (row.classList.contains("hidden")) return
      const qtyEl = row.querySelector("[data-lancamento-item-qty]")
      if (!qtyEl) return
      const n = parseBrDecimal(qtyEl.value)
      qtyEl.value = n != null ? String(n) : ""
    })

    this.recalculate()
  }
}
