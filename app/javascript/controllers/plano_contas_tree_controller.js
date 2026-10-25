import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["branch", "children", "chevron"]

  connect() {
    this.branchTargets.forEach((branch) => {
      const depth = parseInt(branch.dataset.depth || "0", 10)
      const expanded = branch.dataset.expanded !== "false"
      if (depth >= 2 && expanded) {
        this.setExpanded(branch, false)
      } else {
        this.setExpanded(branch, expanded)
      }
    })
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const branch = event.currentTarget.closest("[data-plano-contas-tree-target='branch']")
    if (!branch) return

    const open = branch.dataset.expanded === "true"
    this.setExpanded(branch, !open)
  }

  expandAll() {
    this.branchTargets.forEach((branch) => this.setExpanded(branch, true))
  }

  collapseAll() {
    this.branchTargets.forEach((branch) => {
      const depth = parseInt(branch.dataset.depth || "0", 10)
      this.setExpanded(branch, depth < 1)
    })
  }

  setExpanded(branch, open) {
    branch.dataset.expanded = open ? "true" : "false"
    const children = branch.querySelector(":scope > [data-plano-contas-tree-target='children']")
    const chevron = branch.querySelector(":scope > div [data-plano-contas-tree-target='chevron']")

    if (children) {
      children.classList.toggle("hidden", !open)
    }
    if (chevron) {
      chevron.classList.toggle("rotate-90", open)
    }
  }
}
