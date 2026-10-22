# frozen_string_literal: true

module EscalaExtra
  class PlantaoCartazController < EscalaExtra::BaseController
    include PlantaoExtraCartazRender

    def show
      render_plantao_extra_cartaz
    end

    private

    def plantao_periodo_for_cartaz
      PlantaoPeriodo.find(params[:id])
    end
  end
end
