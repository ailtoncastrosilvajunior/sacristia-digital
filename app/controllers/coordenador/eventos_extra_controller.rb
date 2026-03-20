# frozen_string_literal: true

module Coordenador
  class EventosExtraController < Coordenador::BaseController
    def index
      @eventos = EventoEscala.extras.por_data.page(params[:page])
    end

    def show
      @evento = EventoEscala.find(params[:id])
    end
  end
end
