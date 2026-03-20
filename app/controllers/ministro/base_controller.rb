# frozen_string_literal: true

module Ministro
  class BaseController < ApplicationController
    before_action :authorize_ministro!

    layout "ministro"

    private

    def authorize_ministro!
      return if current_user
      flash[:alert] = "Faça login para acessar."
      redirect_to new_user_session_path
    end
  end
end
