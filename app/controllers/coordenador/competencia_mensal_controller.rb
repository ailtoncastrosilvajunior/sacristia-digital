# frozen_string_literal: true

module Coordenador
  class CompetenciaMensalController < Coordenador::BaseController
    def index
      @competencias = CompetenciaMensal.ordenados.page(params[:page])
    end

    def show
      @competencia = CompetenciaMensal.find(params[:id])
    end
  end
end
