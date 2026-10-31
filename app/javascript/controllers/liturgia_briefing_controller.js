import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "copyButton"]

  copy() {
    const ta = this.textareaTarget
    ta.select()
    ta.setSelectionRange(0, ta.value.length)
    const label = this.copyButtonTarget.textContent
    const ok = () => {
      this.copyButtonTarget.textContent = "Copiado!"
      setTimeout(() => {
        this.copyButtonTarget.textContent = label
      }, 2500)
    }
    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(ta.value).then(ok)
    } else {
      document.execCommand("copy")
      ok()
    }
  }
}
