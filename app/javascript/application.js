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
