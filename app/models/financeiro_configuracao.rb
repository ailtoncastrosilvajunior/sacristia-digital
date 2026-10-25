# frozen_string_literal: true

class FinanceiroConfiguracao < ApplicationRecord
  self.table_name = "financeiro_configuracoes"

  def self.instancia
    first || create!
  end

  def self.migrado?
    instancia.migrado_em.present?
  end

  def self.marcar_migrado!
    instancia.update!(migrado_em: Time.current)
  end
end
