import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "template", "list"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    const mount = this.hasListTarget ? this.listTarget : this.element
    mount.insertAdjacentHTML("beforeend", content)
    this.dispatch("added", { bubbles: true })
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-items-target='item']")
    const destroy = row.querySelector("[data-nested-items-destroy]")
    if (destroy && destroy.name.includes("[_destroy]")) {
      destroy.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
    this.dispatch("removed", { bubbles: true })
  }
}
