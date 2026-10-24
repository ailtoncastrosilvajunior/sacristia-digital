import { Controller } from "@hotwired/stimulus"

// Rola até o bloco de erros após re-render do formulário (ex.: validação falhou no fim da página).
export default class extends Controller {
  connect() {
    requestAnimationFrame(() => {
      this.element.scrollIntoView({ behavior: "smooth", block: "center" })
      this.element.focus({ preventScroll: true })
    })
  }
}
