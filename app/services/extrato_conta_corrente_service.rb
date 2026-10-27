# frozen_string_literal: true

class ExtratoContaCorrenteService
  Linha = Struct.new(:lancamento, :data, :descricao, :natureza, :valor_com_sinal, :saldo_apos, keyword_init: true)
  GrupoDia = Struct.new(:data, :linhas, :total_entradas, :total_saidas, :saldo_final, keyword_init: true) do
    def total_liquido
      total_entradas.to_d - total_saidas.to_d
    end
  end

  def initialize(conta_corrente, de:, ate:)
    @conta = conta_corrente
    @de = de
    @ate = ate
  end

  def saldo_anterior
    saldo_ate(@de - 1.day)
  end

  def saldo_atual
    saldo_ate(@ate)
  end

  def linhas
    saldo = saldo_anterior
    lancamentos.map do |lc|
      saldo += lc.valor_com_sinal
      Linha.new(
        lancamento: lc,
        data: lc.data,
        descricao: descricao_linha(lc),
        natureza: lc.natureza,
        valor_com_sinal: lc.valor_com_sinal,
        saldo_apos: saldo
      )
    end
  end

  def grupos_por_dia
    linhas.group_by(&:data).sort_by(&:first).map do |data, dia_linhas|
      entradas = dia_linhas.sum { |l| l.valor_com_sinal.positive? ? l.valor_com_sinal : 0.to_d }
      saidas = dia_linhas.sum { |l| l.valor_com_sinal.negative? ? -l.valor_com_sinal : 0.to_d }
      GrupoDia.new(
        data: data,
        linhas: dia_linhas,
        total_entradas: entradas,
        total_saidas: saidas,
        saldo_final: dia_linhas.last.saldo_apos
      )
    end
  end

  def totais_periodo
    confirmados = lancamentos
    {
      entradas: confirmados.select(&:entrada?).sum(&:valor_total),
      saidas: confirmados.select(&:saida?).sum(&:valor_total)
    }
  end

  private

  def saldo_ate(data)
    @saldo_ate_cache ||= {}
    return @saldo_ate_cache[data] if @saldo_ate_cache.key?(data)

    base = @conta.saldo_inicial.to_d
    if data < @conta.data_saldo_inicial
      @saldo_ate_cache[data] = base
      return base
    end

    saldo = base
    movimentos_pluck.each do |mov_data, natureza, valor|
      break if mov_data > data

      saldo += natureza == "entrada" ? valor.to_d : -valor.to_d
    end
    @saldo_ate_cache[data] = saldo
  end

  def lancamentos
    @lancamentos ||= @conta.lancamentos_caixa
      .confirmados
      .where(data: @de..@ate)
      .includes({ evento_escala: :sacerdote }, itens_lancamento: :plano_conta)
      .order(:data, :id)
      .to_a
  end

  def movimentos_pluck
    @movimentos_pluck ||= @conta.lancamentos_caixa.confirmados
      .where(data: @conta.data_saldo_inicial..@ate)
      .order(:data, :id)
      .pluck(:data, :natureza, :valor_total)
  end

  def descricao_linha(lc)
    partes = []
    partes << lc.fornecedor if lc.fornecedor.present?
    partes << lc.contado_por if lc.contado_por.present?
    if partes.empty?
      item = lc.itens_lancamento.first
      partes << item.plano_conta.label_completo if item&.plano_conta
      partes << "Lançamento ##{lc.id}"
    end
    partes.join(" · ")
  end
end
