import { Controller } from "@hotwired/stimulus"

const fmt = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" })

const libraryPromises = new Map()

function loadChartFromUrl(url) {
  if (window.Chart) return Promise.resolve(window.Chart)
  if (libraryPromises.has(url)) return libraryPromises.get(url)

  const promise = new Promise((resolve, reject) => {
    const script = document.createElement("script")
    script.src = url
    script.async = true
    script.onload = () => {
      if (window.Chart) resolve(window.Chart)
      else reject(new Error("Chart.js não registrou window.Chart"))
    }
    script.onerror = () => reject(new Error(`Falha ao carregar ${url}`))
    document.head.appendChild(script)
  })

  libraryPromises.set(url, promise)
  return promise
}

export default class extends Controller {
  static targets = ["canvas"]
  static values = { config: Object, library: String }

  async connect() {
    this._onResize = () => this.chart?.resize()
    window.addEventListener("resize", this._onResize)
    try {
      if (window.Chart) {
        this.Chart = window.Chart
      } else {
        const url = this.libraryValue || "/assets/chart.umd.min.js"
        this.Chart = await loadChartFromUrl(url)
      }
      this._renderWhenReady()
    } catch (error) {
      console.error("[financeiro-evolucao-chart]", error)
      this.showFallback("Não foi possível carregar o gráfico. Recarregue a página.")
    }
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize)
    this.chart?.destroy()
    this.chart = null
  }

  configValueChanged() {
    if (this.Chart) this._renderWhenReady()
  }

  showFallback(message) {
    if (!this.hasCanvasTarget) return
    if (this.element.querySelector("[data-chart-fallback]")) return
    this.canvasTarget.classList.add("hidden")
    this.element.insertAdjacentHTML(
      "beforeend",
      `<p data-chart-fallback class="absolute inset-0 flex items-center justify-center text-sm text-slate-500 px-6 text-center">${message}</p>`
    )
  }

  areaGradient(ctx, h, rgb) {
    const g = ctx.createLinearGradient(0, 0, 0, h)
    g.addColorStop(0, `rgba(${rgb}, 0.35)`)
    g.addColorStop(1, `rgba(${rgb}, 0.02)`)
    return g
  }

  _renderWhenReady(attempt = 0) {
    requestAnimationFrame(() => {
      if (this.element.clientHeight < 8 && attempt < 24) {
        this._renderWhenReady(attempt + 1)
        return
      }
      try {
        this.render()
      } catch (error) {
        console.error("[financeiro-evolucao-chart]", error)
        this.showFallback("Erro ao desenhar o gráfico.")
      }
    })
  }

  render() {
    const Chart = this.Chart
    if (!Chart || !this.hasCanvasTarget) return

    const cfg = this.configValue || {}
    const labels = cfg.labels || cfg["labels"] || []
    if (!labels.length) {
      this.showFallback("Sem dados no ano selecionado para montar o gráfico.")
      return
    }

    const entradas = cfg.entradas || cfg["entradas"] || []
    const saidas = cfg.saidas || cfg["saidas"] || []
    const resultadosRaw = cfg.resultados || cfg["resultados"]
    const resultados = resultadosRaw?.length
      ? resultadosRaw
      : labels.map((_, i) => (Number(entradas[i]) || 0) - (Number(saidas[i]) || 0))

    this.chart?.destroy()
    const canvas = this.canvasTarget
    canvas.classList.remove("hidden")
    this.element.querySelector("[data-chart-fallback]")?.remove()

    const ctx = canvas.getContext("2d")
    const h = this.element.clientHeight || 280

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            label: "Entradas",
            data: entradas,
            borderColor: "rgb(16, 185, 129)",
            backgroundColor: this.areaGradient(ctx, h, "16, 185, 129"),
            borderWidth: 2.5,
            pointRadius: 3,
            pointHoverRadius: 5,
            pointBackgroundColor: "#fff",
            pointBorderWidth: 2,
            tension: 0.35,
            fill: true
          },
          {
            label: "Saídas",
            data: saidas,
            borderColor: "rgb(244, 63, 94)",
            backgroundColor: this.areaGradient(ctx, h, "244, 63, 94"),
            borderWidth: 2.5,
            pointRadius: 3,
            pointHoverRadius: 5,
            pointBackgroundColor: "#fff",
            pointBorderWidth: 2,
            tension: 0.35,
            fill: true
          },
          {
            label: "Resultado",
            data: resultados,
            borderColor: "rgb(59, 130, 246)",
            backgroundColor: this.areaGradient(ctx, h, "59, 130, 246"),
            borderWidth: 2.5,
            pointRadius: 3,
            pointHoverRadius: 5,
            pointBackgroundColor: "#fff",
            pointBorderWidth: 2,
            tension: 0.35,
            fill: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: {
            position: "bottom",
            labels: {
              usePointStyle: true,
              pointStyle: "circle",
              padding: 16,
              font: { size: 11, weight: "600" },
              color: "#475569"
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
            grid: { color: "rgba(148, 163, 184, 0.12)" },
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
