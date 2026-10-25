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
