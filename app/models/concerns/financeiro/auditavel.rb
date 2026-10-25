# frozen_string_literal: true

module Financeiro
  module Auditavel
    extend ActiveSupport::Concern

    included do
      after_create :auditoria_criacao
      after_update :auditoria_atualizacao
    end

    def registrar_auditoria!(acao, user: nil, extra: {})
      AuditoriaFinanceira.create!(
        user: user,
        registro: self,
        acao: acao,
        payload: extra.presence || snapshot_auditoria
      )
    end

    private

    def auditoria_criacao
      return if Financeiro::ImportContext.active?

      registrar_auditoria!("criar", user: Current.user)
    end

    def auditoria_atualizacao
      return if Financeiro::ImportContext.active?
      return unless saved_changes?

      registrar_auditoria!("atualizar", user: Current.user)
    end

    def snapshot_auditoria
      attributes.except("created_at", "updated_at")
    end
  end
end
