// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function appPageLoadingEl() {
  return document.getElementById("app-page-loading")
}

function showAppPageLoading() {
  document.documentElement.classList.add("app-loading")
  const el = appPageLoadingEl()
  if (!el) return
  el.classList.remove("opacity-0", "pointer-events-none")
  el.classList.add("opacity-100")
  el.setAttribute("aria-hidden", "false")
}

function hideAppPageLoading() {
  document.documentElement.classList.remove("app-loading")
  const el = appPageLoadingEl()
  if (!el) return
  el.classList.add("opacity-0", "pointer-events-none")
  el.classList.remove("opacity-100")
  el.setAttribute("aria-hidden", "true")
}

document.addEventListener("turbo:before-visit", showAppPageLoading)
document.addEventListener("turbo:load", hideAppPageLoading)
document.addEventListener("turbo:fetch-request-error", hideAppPageLoading)
document.addEventListener("turbo:submit-start", showAppPageLoading)
document.addEventListener("turbo:submit-end", hideAppPageLoading)

// Garante que nenhum overlay (carregando, modal, drawer) fique "preso" na tela
// depois de salvar/redirecionar ou ao voltar por cache/histórico.
function resetOverlays() {
  hideAppPageLoading()
  document.body.classList.remove("overflow-hidden")

  const backdrop = document.getElementById("evento-modal-backdrop")
  if (backdrop) {
    backdrop.classList.add("hidden")
    backdrop.classList.remove("flex")
  }
  document.querySelectorAll("[data-drawer-target=overlay]").forEach((el) => {
    el.classList.add("invisible", "opacity-0", "pointer-events-none")
    el.classList.remove("visible", "opacity-100", "pointer-events-auto")
  })
  document.querySelectorAll("[data-drawer-target=panel]").forEach((el) => el.classList.add("translate-x-full"))
}

document.addEventListener("turbo:before-cache", () => {
  resetOverlays()
  const frame = document.getElementById("evento_modal")
  if (frame) frame.innerHTML = ""
})
document.addEventListener("turbo:render", resetOverlays)
document.addEventListener("turbo:load", resetOverlays)
window.addEventListener("pageshow", resetOverlays)
