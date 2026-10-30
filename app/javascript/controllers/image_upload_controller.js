import { Controller } from "@hotwired/stimulus"

// Seleção de imagem com preview local, clique e arrastar-e-soltar (formulário ainda precisa ser salvo).
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "status", "dropzone"]

  connect() {
    if (this.hasPreviewTarget && this.previewTarget.getAttribute("src")) {
      this.showPreviewElement()
    }
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()
    this.inputTarget.click()
  }

  keydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    this.open(event)
  }

  selected() {
    const file = this.inputTarget.files?.[0]
    if (!file) return
    if (!file.type.startsWith("image/")) {
      this.setStatus("Escolha um arquivo JPG, PNG ou WebP.", "error")
      this.inputTarget.value = ""
      return
    }
    this.previewFromFile(file)
    this.setStatus(`${file.name} — clique em «Salvar alterações» para enviar.`, "ok")
  }

  dragover(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add("border-sky-400", "bg-sky-50", "ring-2", "ring-sky-200")
    }
  }

  dragleave(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-sky-400", "bg-sky-50", "ring-2", "ring-sky-200")
    }
  }

  drop(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-sky-400", "bg-sky-50", "ring-2", "ring-sky-200")
    }
    const file = event.dataTransfer?.files?.[0]
    if (!file) return

    const dt = new DataTransfer()
    dt.items.add(file)
    this.inputTarget.files = dt.files
    this.selected()
  }

  previewFromFile(file) {
    const url = URL.createObjectURL(file)
    if (this.hasPreviewTarget) {
      if (this._objectUrl) URL.revokeObjectURL(this._objectUrl)
      this._objectUrl = url
      this.previewTarget.src = url
      this.previewTarget.alt = file.name
    }
    this.showPreviewElement()
  }

  showPreviewElement() {
    if (this.hasPreviewTarget) this.previewTarget.classList.remove("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
  }

  setStatus(message, kind) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.classList.remove("hidden", "text-emerald-700", "text-red-600", "text-stone-500")
    if (kind === "ok") this.statusTarget.classList.add("text-emerald-700")
    else if (kind === "error") this.statusTarget.classList.add("text-red-600")
    else this.statusTarget.classList.add("text-stone-500")
  }

  disconnect() {
    if (this._objectUrl) URL.revokeObjectURL(this._objectUrl)
  }
}
