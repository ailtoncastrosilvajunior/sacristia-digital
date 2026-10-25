# frozen_string_literal: true

module FinanceiroHelper
  def formatar_moeda(valor)
    number_to_currency(valor.to_d, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def resumo_kpis_mes_referencia(linhas, coluna)
    key = coluna.key
    saldo = linhas.find { |l| l.destaque == :saldo }&.valores&.dig(key).to_d
    entradas = linhas.find { |l| l.destaque == :entrada }&.valores&.dig(key).to_d
    saidas = linhas.find { |l| l.destaque == :despesa }&.valores&.dig(key).to_d
    {
      saldo_anterior: saldo,
      entradas: entradas,
      saidas: saidas,
      saldo_final: saldo + entradas - saidas
    }
  end

  def moeda_resumo_classe(valor)
    v = valor.to_d
    return "text-stone-400" if v.zero?
    return "text-emerald-600" if v.positive?

    "text-red-600"
  end

  RESUMO_GRUPO_THEME = {
    "emerald" => {
      border: "border-emerald-300/80",
      header: "border-emerald-200/90 bg-gradient-to-r from-emerald-50 via-white to-white",
      icon_wrap: "bg-emerald-500/15 text-emerald-700 ring-1 ring-emerald-200/80",
      title: "text-emerald-900",
      col_ref: "bg-emerald-500/10 ring-1 ring-inset ring-emerald-200/60",
      subtotal: "bg-emerald-50/90",
      bar: "bg-emerald-500",
      value: "text-emerald-950"
    },
    "rose" => {
      border: "border-rose-300/80",
      header: "border-rose-200/90 bg-gradient-to-r from-rose-50 via-white to-white",
      icon_wrap: "bg-rose-500/15 text-rose-700 ring-1 ring-rose-200/80",
      title: "text-rose-900",
      col_ref: "bg-rose-500/10 ring-1 ring-inset ring-rose-200/60",
      subtotal: "bg-rose-50/90",
      bar: "bg-rose-500",
      value: "text-rose-950"
    }
  }.freeze

  def resumo_panel_card_classes
    "rounded-2xl border border-slate-200/80 bg-white shadow-lg shadow-slate-200/40 ring-1 ring-slate-100/90"
  end

  RESUMO_MATRIX_COL_REM = {
    conta: 15.0,
    tend: 2.5,
    spark: 3.0,
    periodo: 6.5,
    part: 4.5,
    mes: 5.25
  }.freeze

  def resumo_matrix_min_width_rem(colunas)
    w = RESUMO_MATRIX_COL_REM
    w[:conta] + w[:tend] + w[:spark] + w[:periodo] + w[:part] + (colunas.size * w[:mes])
  end

  def resumo_matrix_col_widths
    RESUMO_MATRIX_COL_REM
  end

  def resumo_grupo_theme(accent)
    RESUMO_GRUPO_THEME.fetch(accent.to_s) { RESUMO_GRUPO_THEME["emerald"] }
  end

  def resumo_saldos_finais_por_coluna(linhas, colunas)
    saldo = linhas.find { |l| l.destaque == :saldo }
    entradas = linhas.find { |l| l.destaque == :entrada }
    saidas = linhas.find { |l| l.destaque == :despesa }
    return {} unless saldo && entradas && saidas

    colunas.to_h do |col|
      k = col.key
      final = saldo.valores[k].to_d + entradas.valores[k].to_d - saidas.valores[k].to_d
      [k, final]
    end
  end

  def resumo_grupos_plano_contas(linhas)
    idx_entrada = linhas.index { |l| l.destaque == :entrada }
    idx_despesa = linhas.index { |l| l.destaque == :despesa }
    {
      saldo: linhas.find { |l| l.destaque == :saldo },
      receitas: {
        header: idx_entrada ? linhas[idx_entrada] : nil,
        linhas: idx_entrada && idx_despesa ? linhas[(idx_entrada + 1)...idx_despesa] : []
      },
      despesas: {
        header: idx_despesa ? linhas[idx_despesa] : nil,
        linhas: idx_despesa ? linhas[(idx_despesa + 1)..] : []
      }
    }
  end

  def resumo_soma_periodo(linha, colunas)
    colunas.sum { |col| linha.valores[col.key].to_d }
  end

  def resumo_participacao_pct(valor, total)
    return nil if total.nil? || total.to_d.zero?

    ((valor.to_d.abs / total.to_d.abs) * 100).round(1)
  end

  def resumo_col_maxes(linhas, colunas)
    keys = colunas.map(&:key)
    maxes = keys.index_with { 0.to_d }.merge(periodo: 0.to_d)
    linhas.each do |linha|
      next unless linha.tipo == :conta

      keys.each { |k| maxes[k] = [maxes[k], linha.valores[k].to_d.abs].max }
      sum = keys.sum { |k| linha.valores[k].to_d.abs }
      maxes[:periodo] = [maxes[:periodo], sum].max
    end
    maxes
  end

  def resumo_intensidade_pct(valor, col_max)
    max = col_max.to_d
    v = valor.to_d.abs
    return nil if max.zero? || v.zero?

    ((v / max) * 100).round(1)
  end

  def resumo_intensidade_bar(valor, col_max, accent)
    pct = resumo_intensidade_pct(valor, col_max)
    return nil unless pct

    theme = resumo_grupo_theme(accent)
    altura = pct.clamp(22, 100)
    opacidade = (0.45 + (pct / 100.0) * 0.55).round(2)

    tag.div(class: "pointer-events-none absolute bottom-1.5 left-0 top-1.5 flex w-1.5 items-end", aria: { hidden: true }) do
      tag.div("", class: "w-full rounded-full #{theme[:bar]}", style: "height: #{altura}%; opacity: #{opacidade}")
    end
  end

  def resumo_sparkline_bars(linha, colunas, accent)
    vals = colunas.first(3).map { |c| linha.valores[c.key].to_d.abs }
    max = vals.max
    return "" if max.zero?

    theme = resumo_grupo_theme(accent)
    bars = vals.reverse.map do |v|
      h_px = (v / max * 18).round.clamp(2, 18)
      tag.div("", class: "w-1.5 rounded-sm #{theme[:bar]}/70", style: "height: #{h_px}px", aria: { hidden: true })
    end
    tag.div(class: "flex h-5 w-10 items-end justify-center gap-0.5", title: "Últimos 3 meses (→ mais recente)") do
      safe_join(bars)
    end
  end

  def resumo_tendencia_linha(linha, colunas)
    return :flat if colunas.size < 2

    atual = linha.valores[colunas[0].key].to_d.abs
    anterior = linha.valores[colunas[1].key].to_d.abs
    return :flat if atual == anterior

    atual > anterior ? :up : :down
  end

  def resumo_tendencia_mark(kind)
    title =
      case kind
      when :up then "Subiu em relação ao mês anterior"
      when :down then "Caiu em relação ao mês anterior"
      else "Estável em relação ao mês anterior"
      end

    cfg =
      case kind
      when :up
        { wrap: "bg-emerald-50 ring-1 ring-emerald-200/90", icon: "text-emerald-700", d: "M4.5 15.75l7.5-7.5 7.5 7.5" }
      when :down
        { wrap: "bg-rose-50 ring-1 ring-rose-200/90", icon: "text-rose-700", d: "M19.5 8.25l-7.5 7.5-7.5-7.5" }
      else
        { wrap: "bg-slate-100 ring-1 ring-slate-200/90", icon: "text-slate-600", d: "M3.75 8.25h16.5M3.75 15.75h16.5" }
      end

    path = tag.path("stroke-linecap": "round", "stroke-linejoin": "round", d: cfg[:d])
    svg = tag.svg(path, xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24",
                  class: "h-3.5 w-3.5 shrink-0 #{cfg[:icon]}", "stroke-width": "2", stroke: "currentColor", "aria-hidden": "true")
    tag.span(svg, class: "inline-flex h-6 w-6 items-center justify-center rounded-full #{cfg[:wrap]}", title: title, role: "img", "aria-label": title)
  end

  def resumo_periodos_stats(periodos, totais_ano, periodo_ref)
    com_movimento = periodos.reject(&:futuro)
    n = com_movimento.size
    entradas = totais_ano[:entradas].to_d
    saidas = totais_ano[:saidas].to_d
    resultado = entradas - saidas
    ref_resultado = periodo_ref ? periodo_ref.entradas.to_d - periodo_ref.saidas.to_d : 0.to_d

    {
      meses: n,
      entradas: entradas,
      saidas: saidas,
      resultado: resultado,
      saldo_final: totais_ano[:saldo_final].to_d,
      media_entradas: n.positive? ? entradas / n : 0.to_d,
      media_saidas: n.positive? ? saidas / n : 0.to_d,
      resultado_mes_ref: ref_resultado,
      margem_pct: resumo_margem_liquida_pct(resultado, entradas),
      variacao_resultado_ref_pct: resumo_variacao_resultado_mes_pct(periodos, periodo_ref)
    }
  end

  def resumo_margem_liquida_pct(resultado, entradas)
    return nil if entradas.to_d.zero?

    ((resultado.to_d / entradas.to_d) * 100).round(1)
  end

  def resumo_variacao_resultado_mes_pct(periodos, periodo_ref)
    return nil unless periodo_ref

    idx = periodos.index(periodo_ref)
    return nil unless idx&.positive?

    anterior = periodos[idx - 1]
    return nil if anterior.futuro

    res_ant = anterior.entradas.to_d - anterior.saidas.to_d
    res_at = periodo_ref.entradas.to_d - periodo_ref.saidas.to_d
    return nil if res_ant.zero?

    (((res_at - res_ant) / res_ant.abs) * 100).round(1)
  end

  def resumo_periodos_col_maxes(periodos)
    visiveis = periodos.reject(&:futuro)
    {
      entradas: visiveis.map { |p| p.entradas.to_d }.max || 0.to_d,
      saidas: visiveis.map { |p| p.saidas.to_d }.max || 0.to_d
    }
  end

  def resumo_chip_variacao(pct)
    return tag.span("—", class: "text-slate-400 text-xs") if pct.nil?

    positivo = pct >= 0
    cls = positivo ? "bg-emerald-50 text-emerald-800 ring-emerald-200/80" : "bg-rose-50 text-rose-800 ring-rose-200/80"
    sinal = positivo ? "+" : ""
    tag.span("#{sinal}#{number_with_precision(pct, precision: 1, separator: ',')}% vs mês ant.",
             class: "inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold tabular-nums ring-1 #{cls}")
  end

  def resumo_celula_moeda_bar(valor, col_max, accent, ref: false, futuro: false)
    theme = resumo_grupo_theme(accent)
    v = valor.to_d
    td_extras = ref ? theme[:col_ref] : ""

    if futuro || v.zero?
      return tag.td(class: "relative px-3 py-2.5 text-right tabular-nums #{td_extras}") do
        tag.span("—", class: "text-[11px] font-medium text-slate-300")
      end
    end

    tag.td(class: "relative px-3 py-2.5 text-right tabular-nums #{td_extras}") do
      safe_join([
        resumo_intensidade_bar(v, col_max, accent),
        tag.span(formatar_moeda(v), class: "relative z-[1] text-[11px] font-semibold #{accent == 'emerald' ? 'text-emerald-900' : 'text-rose-900'}")
      ])
    end
  end

  def resumo_celula_valor(valor, col_max, accent, ref_column: false)
    theme = resumo_grupo_theme(accent)
    v = valor.to_d
    td_extras = ref_column ? theme[:col_ref] : ""

    if v.zero?
      return tag.td(class: "relative px-2 py-2 text-right tabular-nums #{td_extras}") do
        tag.span("—", class: "text-[11px] font-medium text-slate-300", title: "Sem movimento no mês")
      end
    end

    tag.td(class: "relative px-2 py-2 text-right tabular-nums #{td_extras}") do
      safe_join([
        resumo_intensidade_bar(v, col_max, accent),
        tag.span(formatar_moeda(v), class: "relative z-[1] text-[11px] font-semibold text-slate-900")
      ])
    end
  end

  # Linha secundária do extrato: conta (código + descrição) dos itens + observações.
  def extrato_detalhe_conferencia(lancamento, titulo: nil)
    titulo = titulo.presence || lancamento.fornecedor.presence || lancamento.contado_por.presence || ""
    fragmentos = []

    contas = lancamento.itens_lancamento.filter_map do |item|
      pc = item.plano_conta
      next unless pc

      desc = item.descricao.presence || pc.nome
      linha = "#{pc.codigo} — #{desc}"
      linha unless titulo.include?(linha) || (desc.present? && titulo.include?(desc) && titulo.include?(pc.codigo))
    end.uniq
    fragmentos << contas.join(" · ") if contas.any?

    if lancamento.observacoes.present?
      obs = lancamento.observacoes.strip
      fragmentos << "Obs: #{obs}" unless titulo.include?(obs)
    end

    fragmentos.join(" — ")
  end

  def badge_natureza_lancamento(natureza)
    if natureza == "entrada"
      tag.span "Entrada", class: "inline-flex px-2 py-0.5 text-xs font-semibold rounded-full bg-emerald-100 text-emerald-900"
    else
      tag.span "Saída", class: "inline-flex px-2 py-0.5 text-xs font-semibold rounded-full bg-red-100 text-red-900"
    end
  end
end
