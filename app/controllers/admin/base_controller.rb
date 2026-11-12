# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    include Buscavel

    before_action :authorize_admin!
    before_action :require_instituicao_recurso_escala_mesc!

    layout "admin"

    private

    def authorize_admin!
      return if current_user&.admin?
      flash[:alert] = "Acesso restrito a administradores."
      redirect_to root_path
    end

    def require_instituicao_recurso_escala_mesc!
      require_instituicao_recurso!(:escala_mesc)
    end
  end
end
