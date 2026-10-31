import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item", "empty", "count"]

  filter() {
    const query = this.normalize(this.inputTarget.value)
    let visible = 0
    this.itemTargets.forEach((el) => {
      const haystack = this.normalize(el.dataset.search || "")
      const show = !query || haystack.includes(query)
      el.classList.toggle("hidden", !show)
      if (show) visible += 1
    })
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible > 0)
    }
    if (this.hasCountTarget && query) {
      this.countTarget.textContent = `${visible} resultado(s)`
      this.countTarget.classList.remove("hidden")
    } else if (this.hasCountTarget) {
      this.countTarget.classList.add("hidden")
    }
  }

  normalize(value) {
    return (value || "")
      .trim()
      .toLowerCase()
      .normalize("NFD")
      .replace(/\p{Diacritic}/gu, "")
  }
}
