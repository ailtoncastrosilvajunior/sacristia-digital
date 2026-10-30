import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "expandButton", "collapseButton"]
  static values = { storageKey: { type: String, default: "sacristia-sidebar-collapsed" } }

  connect() {
    this.boundClose = this.close.bind(this)
    document.addEventListener("turbo:before-visit", this.boundClose)

    this.mediaQuery = window.matchMedia("(min-width: 1024px)")
    this.boundMediaChange = this.onMediaChange.bind(this)
    this.mediaQuery.addEventListener("change", this.boundMediaChange)

    if (this.isDesktop()) {
      this.applyCollapsed(this.readCollapsed(), { persist: false })
    } else {
      this.updateDesktopToggleUi()
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.boundClose)
    this.mediaQuery?.removeEventListener("change", this.boundMediaChange)
  }

  isDesktop() {
    return this.mediaQuery?.matches ?? window.matchMedia("(min-width: 1024px)").matches
  }

  readCollapsed() {
    try {
      return localStorage.getItem(this.storageKeyValue) === "1"
    } catch {
      return false
    }
  }

  toggleDesktop() {
    if (!this.isDesktop()) return

    const collapsed = this.element.dataset.collapsed === "true"
    this.applyCollapsed(!collapsed, { persist: true })
  }

  applyCollapsed(collapsed, { persist = true } = {}) {
    this.element.dataset.collapsed = collapsed ? "true" : "false"

    if (persist) {
      try {
        localStorage.setItem(this.storageKeyValue, collapsed ? "1" : "0")
      } catch {
        /* ignore */
      }
    }

    this.updateDesktopToggleUi()
  }

  updateDesktopToggleUi() {
    const collapsed = this.element.dataset.collapsed === "true"
    const desktop = this.isDesktop()

    if (this.hasSidebarTarget) {
      const hidden = collapsed && desktop
      this.sidebarTarget.setAttribute("aria-hidden", hidden ? "true" : "false")
    }

    if (this.hasCollapseButtonTarget) {
      this.collapseButtonTarget.classList.toggle("lg:hidden", !desktop || collapsed)
    }

    if (this.hasExpandButtonTarget) {
      const showExpand = desktop && collapsed
      this.expandButtonTarget.classList.toggle("hidden", !showExpand)
      this.expandButtonTarget.classList.toggle("inline-flex", showExpand)
    }
  }

  onMediaChange() {
    if (this.isDesktop()) {
      this.applyCollapsed(this.readCollapsed(), { persist: false })
      this.closeMobileDrawer()
    } else {
      this.element.dataset.collapsed = "false"
      this.updateDesktopToggleUi()
    }
  }

  toggle() {
    if (this.isDesktop()) {
      this.toggleDesktop()
      return
    }

    this.sidebarTarget.classList.toggle("-translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.toggle("invisible")
      this.overlayTarget.classList.toggle("opacity-0")
      this.overlayTarget.classList.toggle("pointer-events-none")
      document.body.classList.toggle("overflow-hidden")
    }
  }

  close() {
    this.closeMobileDrawer()
  }

  closeMobileDrawer() {
    if (this.isDesktop()) return

    this.sidebarTarget.classList.add("-translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("invisible", "opacity-0", "pointer-events-none")
      document.body.classList.remove("overflow-hidden")
    }
  }
}
