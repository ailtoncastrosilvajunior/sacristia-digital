import { Controller } from "@hotwired/stimulus"

// Mensagem flash (notice/alert) com botão para fechar.
export default class extends Controller {
  close() {
    this.element.remove()
  }
}
