# frozen_string_literal: true

module PainelSacerdote
  class DashboardController < PainelSacerdote::BaseController
    def index
      @sacerdote = current_user.sacerdote
    end
  end
end
