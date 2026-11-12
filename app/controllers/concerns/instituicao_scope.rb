# frozen_string_literal: true

# Helpers para consultas sempre limitadas à instituição da requisição (Current.instituicao).
module InstituicaoScope
  extend ActiveSupport::Concern

  included do
    before_action :ensure_user_belongs_to_instituicao!, if: :user_signed_in?
  end

  private

  def ensure_user_belongs_to_instituicao!
    return if Current.instituicao.blank?
    return if current_user.instituicao_id == Current.instituicao.id

    sign_out(current_user)
    redirect_to new_user_session_path,
                alert: "Sua conta não pertence a esta instituição. Acesse pelo endereço correto do seu grupo.",
                status: :see_other
  end

  def scoped(relation)
    relation.respond_to?(:da_instituicao_atual) ? relation.da_instituicao_atual : relation
  end

  def find_scoped!(model_class, id)
    scoped(model_class).find(id)
  end

  def competencia_instituicao!(id)
    find_scoped!(CompetenciaMensal, id)
  end

  def evento_instituicao!(id)
    EventoEscala.da_instituicao_atual.find(id)
  end

  def competencia_instituicao_atual_mes
    scoped(CompetenciaMensal).find_by(ano: Date.current.year, mes: Date.current.month)
  end

  def competencia_instituicao_resolvida
    if params[:competencia_mensal_id].present?
      return competencia_instituicao!(params[:competencia_mensal_id])
    end

    competencia_instituicao_atual_mes || scoped(CompetenciaMensal).ordenados.first
  end
end
