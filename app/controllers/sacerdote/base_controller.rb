# frozen_string_literal: true

module Sacerdote
  class BaseController < ApplicationController
    before_action :authorize_sacerdote!

    layout "application"

    private

    def authorize_sacerdote!
      return if current_user&.sacerdote?

      flash[:alert] = "Acesso restrito a usuários com perfil sacerdote."
      redirect_to root_path
    end
  end
end
