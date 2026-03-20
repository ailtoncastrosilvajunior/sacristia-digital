# frozen_string_literal: true

module Coordenador
  class MinistrosController < Coordenador::BaseController
    def index
      @ministros = Ministro.ordenados_por_nome.page(params[:page])
    end

    def show
      @ministro = Ministro.find(params[:id])
    end
  end
end
