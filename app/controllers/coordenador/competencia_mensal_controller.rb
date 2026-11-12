# frozen_string_literal: true

module Coordenador
  class CompetenciaMensalController < Coordenador::BaseController
    def index
      @competencias = scoped(CompetenciaMensal).ordenados.page(params[:page])
    end

    def show
      @competencia = find_scoped!(CompetenciaMensal, params[:id])
    end
  end
end
