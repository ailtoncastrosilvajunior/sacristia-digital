# frozen_string_literal: true

module Coordenador
  class MinistrosController < Coordenador::BaseController
    def index
      @ministros = scoped(Ministro).ordenados_por_nome.page(params[:page])
    end

    def show
      @ministro = find_scoped!(Ministro, params[:id])
    end
  end
end
