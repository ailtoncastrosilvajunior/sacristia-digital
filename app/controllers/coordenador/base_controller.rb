# frozen_string_literal: true

module Coordenador
  class BaseController < ApplicationController
    before_action :authorize_coordenador!

    layout "admin"

    private

    def authorize_coordenador!
      return if current_user&.admin? || current_user&.coordenador?
      flash[:alert] = "Acesso restrito a coordenadores."
      redirect_to root_path
    end
  end
end
