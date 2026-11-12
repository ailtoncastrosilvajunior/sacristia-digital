# frozen_string_literal: true

module SetCurrentInstituicao
  extend ActiveSupport::Concern

  included do
    before_action :set_current_instituicao
    before_action :require_instituicao_ativa!
  end

  private

  def set_current_instituicao
    Current.instituicao = Instituicoes::Resolver.call(request)
  end

  def require_instituicao_ativa!
    return if Current.instituicao.present?

    raise ActionController::RoutingError, "Instituição não encontrada"
  end

  def current_host_for_urls
    @request.host_with_port
  end
end
