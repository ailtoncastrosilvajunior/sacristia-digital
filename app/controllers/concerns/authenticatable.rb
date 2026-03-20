# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def current_user_admin?
    current_user&.admin?
  end

  def current_user_coordenador?
    current_user&.coordenador?
  end

  def current_user_ministro?
    current_user&.ministro?
  end
end
