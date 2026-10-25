# frozen_string_literal: true

class AuditoriaFinanceira < ApplicationRecord
  self.table_name = "auditorias_financeiras"

  belongs_to :user, optional: true
  belongs_to :registro, polymorphic: true

  validates :acao, presence: true

  serialize :payload, coder: JSON
end
