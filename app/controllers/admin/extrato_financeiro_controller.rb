# frozen_string_literal: true

module Admin
  class ExtratoFinanceiroController < Admin::BaseController
    def show
      @conta = ContaCorrente.padrao
      @ano = (params[:ano] || Date.current.year).to_i
      @mes = (params[:mes] || Date.current.month).to_i
      inicio = Date.new(@ano, @mes, 1)
      fim = inicio.end_of_month

      # Filtro opcional de datas, restrito ao mês/ano informado.
      # Sem datas válidas, assume o primeiro e o último dia do mês.
      @de = data_do_dia(params[:dia_de], inicio) || inicio
      @ate = data_do_dia(params[:dia_ate], inicio) || fim
      @de, @ate = @ate, @de if @ate < @de
      @filtro_datas = @de != inicio || @ate != fim

      @extrato = ExtratoContaCorrenteService.new(@conta, de: @de, ate: @ate)
      @grupos = @extrato.grupos_por_dia
      @saldo_anterior = @extrato.saldo_anterior
      @saldo_atual = @extrato.saldo_atual
      @totais = @extrato.totais_periodo
    end

    private

    # Converte o dia informado (1..último dia) em data dentro do mês; nil se inválido.
    def data_do_dia(valor, inicio)
      return nil unless valor.to_s.match?(/\A\d{1,2}\z/)

      dia = valor.to_i.clamp(1, inicio.end_of_month.day)
      Date.new(inicio.year, inicio.month, dia)
    end
  end
end
