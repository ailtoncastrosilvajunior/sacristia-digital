# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SetCurrentInstituicao
  include InstituicaoScope
  include InstituicaoRecursoGate

  before_action :authenticate_user!
  before_action :set_current_user
  before_action :configure_permitted_parameters, if: :devise_controller?

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :instituicao_recurso?

  protected

  def instituicao_recurso?(chave)
    Current.instituicao&.recurso?(chave)
  end

  def require_instituicao_recurso!(chave)
    return if instituicao_recurso?(chave)

    raise ActionController::RoutingError, "Not Found"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nome])
    devise_parameter_sanitizer.permit(:account_update, keys: [:nome])
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def user_not_authorized
    flash[:alert] = "Você não está autorizado a realizar esta ação."
    redirect_to(request.referer || root_path)
  end
end
