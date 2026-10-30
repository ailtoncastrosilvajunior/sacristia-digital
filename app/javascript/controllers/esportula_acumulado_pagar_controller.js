import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "destinatarioNome",
    "saldo",
    "destinatarioTipo",
    "destinatarioEsportulaId",
    "destinatarioSacerdoteId",
    "dataPagamento"
  ]

  open(event) {
    event.preventDefault()
    const { destinatarioTipo, destinatarioEsportulaId, destinatarioSacerdoteId, nome, saldo } =
      event.currentTarget.dataset

    if (this.hasDestinatarioNomeTarget) this.destinatarioNomeTarget.textContent = nome || "—"
    if (this.hasSaldoTarget) this.saldoTarget.textContent = saldo || ""

    if (this.hasDestinatarioTipoTarget) this.destinatarioTipoTarget.value = destinatarioTipo || ""

    if (this.hasDestinatarioEsportulaIdTarget) {
      this.destinatarioEsportulaIdTarget.value =
        destinatarioTipo === "instituicao" ? destinatarioEsportulaId || "" : ""
    }
    if (this.hasDestinatarioSacerdoteIdTarget) {
      this.destinatarioSacerdoteIdTarget.value =
        destinatarioTipo === "sacerdote" ? destinatarioSacerdoteId || "" : ""
    }
    if (this.hasDataPagamentoTarget && !this.dataPagamentoTarget.value) {
      this.dataPagamentoTarget.valueAsDate = new Date()
    }

    this.drawerController()?.open()
  }

  drawerController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "drawer")
  }
}
