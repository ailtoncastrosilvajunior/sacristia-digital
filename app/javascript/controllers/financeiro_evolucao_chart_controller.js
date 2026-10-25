import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

const fmt = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" })

export default class extends Controller {
  static targets = ["canvas"]
  static values = { config: Object }

  connect() {
    this._onResize = () => this.resize()
    window.addEventListener("resize", this._onResize)
    requestAnimationFrame(() => {
      try {
        this.render()
      } catch (error) {
        console.error("[financeiro-evolucao-chart]", error)
        this.showFallback("Não foi possível carregar o gráfico. Recarregue a página.")
      }
    })
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize)
    this.chart?.destroy()
    this.chart = null
  }

  configValueChanged() {
    requestAnimationFrame(() => this.render())
  }

  resize() {
    this.chart?.resize()
  }

  showFallback(message) {
    if (!this.hasCanvasTarget) return
    const wrap = this.canvasTarget.parentElement
    if (!wrap) return
    this.canvasTarget.classList.add("hidden")
    wrap.insertAdjacentHTML(
      "beforeend",
      `<p class="absolute inset-0 flex items-center justify-center text-sm text-slate-500 px-6 text-center">${message}</p>`
    )
  }

  render() {
    const cfg = this.configValue
    if (!cfg?.labels?.length || !this.hasCanvasTarget) {
      if (this.hasCanvasTarget && (!cfg?.labels || cfg.labels.length === 0)) {
        this.showFallback("Sem dados no ano selecionado para montar o gráfico.")
      }
      return
    }

    this.chart?.destroy()
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    const h = canvas.parentElement?.clientHeight || 280

    const gradEntrada = ctx.createLinearGradient(0, 0, 0, h)
    gradEntrada.addColorStop(0, "rgba(16, 185, 129, 0.95)")
    gradEntrada.addColorStop(1, "rgba(52, 211, 153, 0.55)")

    const gradSaida = ctx.createLinearGradient(0, 0, 0, h)
    gradSaida.addColorStop(0, "rgba(244, 63, 94, 0.92)")
    gradSaida.addColorStop(1, "rgba(251, 113, 133, 0.5)")

    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: cfg.labels,
        datasets: [
          {
            type: "bar",
            label: "Entradas",
            data: cfg.entradas,
            backgroundColor: gradEntrada,
            borderRadius: 6,
            borderSkipped: false,
            order: 2
          },
          {
            type: "bar",
            label: "Saídas",
            data: cfg.saidas,
            backgroundColor: gradSaida,
            borderRadius: 6,
            borderSkipped: false,
            order: 3
          },
          {
            type: "line",
            label: "Saldo final",
            data: cfg.saldos,
            borderColor: "rgb(30, 58, 138)",
            backgroundColor: "rgba(59, 130, 246, 0.12)",
            borderWidth: 3,
            pointRadius: 4,
            pointHoverRadius: 6,
            pointBackgroundColor: "#fff",
            pointBorderWidth: 2,
            tension: 0.35,
            fill: true,
            order: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: {
            position: "top",
            align: "end",
            labels: {
              usePointStyle: true,
              pointStyle: "circle",
              padding: 12,
              font: { size: 11, weight: "600" }
            }
          },
          tooltip: {
            backgroundColor: "rgba(15, 23, 42, 0.92)",
            titleFont: { size: 12, weight: "700" },
            bodyFont: { size: 11 },
            padding: 12,
            cornerRadius: 10,
            callbacks: {
              label: (context) => `${context.dataset.label}: ${fmt.format(context.parsed.y)}`
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { font: { size: 10, weight: "600" }, color: "#64748b" }
          },
          y: {
            grid: { color: "rgba(148, 163, 184, 0.2)" },
            ticks: {
              font: { size: 10 },
              color: "#64748b",
              maxTicksLimit: 8,
              callback: (v) => fmt.format(v)
            }
          }
        }
      }
    })
  }
}
