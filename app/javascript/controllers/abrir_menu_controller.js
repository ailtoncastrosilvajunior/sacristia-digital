import { Controller } from "@hotwired/stimulus"

// Botão "Menu" da barra inferior: abre o menu da conta (<details>) do cabeçalho.
export default class extends Controller {
  abrir(e) {
    e.stopPropagation() // evita o "clicar fora" do dropdown fechar o menu no mesmo clique
    const menu = document.querySelector("header details")
    if (!menu) return
    menu.open = !menu.open
    if (menu.open) window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
