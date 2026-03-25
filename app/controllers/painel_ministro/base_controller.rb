# frozen_string_literal: true

module PainelMinistro
  class BaseController < ApplicationController
    before_action :authorize_ministro!

    layout "ministro"

    private

    def authorize_ministro!
      unless current_user&.pode_acessar_dashboard_ministro?
        flash[:alert] = "Você não tem permissão para acessar esta área."
        redirect_to root_path
        return
      end

      unless current_user.ministro.present?
        flash[:alert] = "Sua conta ainda não está vinculada a um cadastro de ministro. Peça ao administrador da paróquia."
        redirect_to root_path
      end
    end
  end
end
