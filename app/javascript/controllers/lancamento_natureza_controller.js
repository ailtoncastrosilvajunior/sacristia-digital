import { Controller } from "@hotwired/stimulus"

// Recarrega o formulário ao mudar a natureza (atualiza campos e contas dos itens).
export default class extends Controller {
  reload(event) {
    const url = new URL(window.location.href)
    url.searchParams.set("natureza", event.target.value)
    window.location.assign(url.toString())
  }
}
