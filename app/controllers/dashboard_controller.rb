# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    case current_user.perfil_principal_redirect
    when :admin
      redirect_to admin_root_path
    when :coordenador
      redirect_to coordenador_root_path
    when :ministro
      redirect_to ministro_root_path
    when :sacerdote
      redirect_to sacerdote_root_path
    else
      redirect_to admin_root_path
    end
  end
end
