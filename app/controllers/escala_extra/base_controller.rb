# frozen_string_literal: true

module EscalaExtra
  # Área restrita aos agendadores da escala extra (e administradores).
  class BaseController < ApplicationController
    include Buscavel

    before_action :authorize_escala_extra!

    layout "escala_extra"

    private

    def authorize_escala_extra!
      return if current_user&.pode_gerenciar_eventos_extra?

      flash[:alert] = "Acesso restrito à escala extra."
      redirect_to root_path
    end
  end
end
