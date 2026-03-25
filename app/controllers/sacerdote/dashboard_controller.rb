# frozen_string_literal: true

module Sacerdote
  class DashboardController < Sacerdote::BaseController
    def index
      @sacerdote = current_user.sacerdote
    end
  end
end
