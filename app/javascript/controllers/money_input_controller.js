import { Controller } from "@hotwired/stimulus"
import { formatBrMoney, parseBrDecimal } from "utils/br_currency"

export default class extends Controller {
  static targets = ["field"]
  static values = { decimals: { type: Number, default: 2 }, readonly: { type: Boolean, default: false } }

  connect() {
    this.syncDisplayFromField()
  }

  focus() {
    const el = this.fieldTarget
    delete el.dataset.rawValue
    const n = parseBrDecimal(el.value)
    if (n != null) el.value = String(n).replace(".", ",")
  }

  blur() {
    this.syncDisplayFromField()
    this.dispatch("changed", { bubbles: true })
  }

  input() {
    if (this.readonlyValue) return
    this.dispatch("changed", { bubbles: true })
  }

  syncDisplayFromField() {
    const el = this.fieldTarget
    const n = parseBrDecimal(el.value)
    if (n == null) {
      el.value = ""
      delete el.dataset.rawValue
      return
    }
    el.dataset.rawValue = String(n)
    el.value = formatBrMoney(n, { decimals: this.decimalsValue })
  }

  numericValue() {
    return parseBrDecimal(this.fieldTarget.value)
  }

  setNumericValue(n) {
    const el = this.fieldTarget
    if (n == null || !Number.isFinite(n)) {
      el.value = ""
      delete el.dataset.rawValue
      return
    }
    el.dataset.rawValue = String(n)
    el.value = formatBrMoney(n, { decimals: this.decimalsValue })
  }

  beforeSubmit() {
    const el = this.fieldTarget
    const n = this.numericValue()
    el.value = n != null ? n.toFixed(this.decimalsValue) : ""
    delete el.dataset.rawValue
  }
}
