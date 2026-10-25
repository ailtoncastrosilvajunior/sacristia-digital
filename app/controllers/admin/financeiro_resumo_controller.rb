# frozen_string_literal: true

module Admin
  class FinanceiroResumoController < Admin::BaseController
    ABAS = %w[periodos plano_contas].freeze

    def show
      @ano = (params[:ano] || Date.current.year).to_i
      @mes = (params[:mes] || Date.current.month).to_i
      @aba = ABAS.include?(params[:aba]) ? params[:aba] : "plano_contas"
      @ano_foco = (params[:ano_foco] || @ano).to_i
      @anos_disponiveis = Financeiro::ResumoPeriodosService.anos_disponiveis

      if @aba == "plano_contas"
        @resumo = Financeiro::ResumoGerencialService.new(ano: @ano, mes: @mes)
        @colunas = @resumo.colunas
        @linhas = @resumo.linhas
      else
        @resumo_periodos = Financeiro::ResumoPeriodosService.new(ano: @ano_foco)
        @periodos = @resumo_periodos.periodos
        @totais_ano = @resumo_periodos.totais_ano
        @chart_config = @resumo_periodos.chart_config
        ref = @periodos.find { |p| p.ano == @ano && p.mes == @mes && !p.futuro } ||
              @periodos.reject(&:futuro).last
        @periodo_ref = ref
      end
    end
  end
end
