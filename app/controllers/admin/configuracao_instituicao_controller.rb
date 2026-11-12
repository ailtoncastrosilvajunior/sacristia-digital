# frozen_string_literal: true

module Admin
  class ConfiguracaoInstituicaoController < BaseController
    skip_before_action :require_instituicao_recurso_escala_mesc!

    before_action :set_instituicao

    def show
    end

    def update
      if @instituicao.update(instituicao_params)
        redirect_to admin_configuracao_instituicao_path, notice: "Configurações da instituição atualizadas."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_instituicao
      @instituicao = Current.instituicao
      return if @instituicao.present?

      raise ActionController::RoutingError, "Instituição não encontrada"
    end

    def instituicao_params
      params.require(:instituicao).permit(:nome, :nome_curto, :slogan_rodape, :nome_recibos, :tipo)
    end
  end
end
