# frozen_string_literal: true

module Financeiro
  class ResumoPeriodosService
    Periodo = Struct.new(:ano, :mes, :label, :saldo_anterior, :entradas, :saidas, :saldo_final, :futuro, keyword_init: true)

    def initialize(ano:, conta: ContaCorrente.padrao)
      @ano = ano
      @conta = conta
    end

    def self.anos_disponiveis
      min_data = LancamentoCaixa.confirmados.minimum(:data)
      min_ano = min_data&.year || Date.current.year
      max_ano = [LancamentoCaixa.confirmados.maximum(:data)&.year, Date.current.year].compact.max
      (min_ano..max_ano).to_a.reverse
    end

    def periodos
      @periodos ||= (1..12).map { |mes| periodo_mes(@ano, mes) }
    end

    def totais_ano
      @totais_ano ||= begin
        com_movimento = periodos.reject(&:futuro)
        {
          entradas: com_movimento.sum { |p| p.entradas.to_d },
          saidas: com_movimento.sum { |p| p.saidas.to_d },
          saldo_final: com_movimento.last&.saldo_final.to_d
        }
      end
    end

    def chart_config
      visiveis = periodos.reject(&:futuro)
      {
        labels: visiveis.map(&:label),
        entradas: visiveis.map { |p| p.entradas.to_f },
        saidas: visiveis.map { |p| p.saidas.to_f },
        saldos: visiveis.map { |p| p.saldo_final.to_f }
      }
    end

    private

    def periodo_mes(ano, mes)
      de = Date.new(ano, mes, 1)
      futuro = de > Date.current.beginning_of_month
      label = format("%02d/%d", mes, ano)
      saldo_ant = saldo_ate(de - 1.day)

      if futuro
        return Periodo.new(
          ano: ano, mes: mes, label: label,
          saldo_anterior: saldo_ant, entradas: 0, saidas: 0, saldo_final: saldo_ant,
          futuro: true
        )
      end

      ate = de.end_of_month
      t = totais_por_mes[[ano, mes]]

      Periodo.new(
        ano: ano,
        mes: mes,
        label: label,
        saldo_anterior: saldo_ant,
        entradas: t[:entradas],
        saidas: t[:saidas],
        saldo_final: saldo_ate(ate),
        futuro: false
      )
    end

    def data_limite_movimentos
      if @ano > Date.current.year
        Date.new(@ano, 1, 1).prev_day
      elsif @ano == Date.current.year
        Date.current
      else
        Date.new(@ano, 12, 31)
      end
    end

    def movimentos
      @movimentos ||= @conta.lancamentos_caixa.confirmados
        .where(data: @conta.data_saldo_inicial..data_limite_movimentos)
        .order(:data, :id)
        .pluck(:data, :natureza, :valor_total)
    end

    def totais_por_mes
      @totais_por_mes ||= movimentos.each_with_object(month_totals_hash) do |(data, natureza, valor), acc|
        key = [data.year, data.month]
        if natureza == "entrada"
          acc[key][:entradas] += valor.to_d
        else
          acc[key][:saidas] += valor.to_d
        end
      end
    end

    def month_totals_hash
      Hash.new { |h, k| h[k] = { entradas: 0.to_d, saidas: 0.to_d } }
    end

    def saldo_ate(data)
      @saldo_ate_cache ||= {}
      return @saldo_ate_cache[data] if @saldo_ate_cache.key?(data)

      base = @conta.saldo_inicial.to_d
      if data < @conta.data_saldo_inicial
        @saldo_ate_cache[data] = base
        return base
      end

      saldo = base
      movimentos.each do |mov_data, natureza, valor|
        break if mov_data > data

        saldo += natureza == "entrada" ? valor.to_d : -valor.to_d
      end
      @saldo_ate_cache[data] = saldo
    end
  end
end
