# frozen_string_literal: true

module Admin
  class ExtratoFinanceiroController < Admin::BaseController
    def show
      @conta = ContaCorrente.padrao
      @ano = (params[:ano] || Date.current.year).to_i
      @mes = (params[:mes] || Date.current.month).to_i
      inicio = Date.new(@ano, @mes, 1)
      fim = inicio.end_of_month

      @extrato = ExtratoContaCorrenteService.new(@conta, de: inicio, ate: fim)
      @grupos = @extrato.grupos_por_dia
      @saldo_anterior = @extrato.saldo_anterior
      @saldo_atual = @extrato.saldo_atual
      @totais = @extrato.totais_periodo
    end
  end
end
