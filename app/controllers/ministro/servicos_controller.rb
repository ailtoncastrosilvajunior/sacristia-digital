# frozen_string_literal: true

module Ministro
  class ServicosController < Ministro::BaseController
    def index
      # Serviços do ministro logado - será implementado na Fase 4
      @servicos = []
    end

    def show
      @servico = EventoEscala.find(params[:id])
    end

    def confirmar
      @servico = EventoEscala.find(params[:id])
      # Lógica de confirmação - será implementada na Fase 4
      redirect_to ministro_meus_servicos_path, notice: "Confirmação registrada."
    end
  end
end
