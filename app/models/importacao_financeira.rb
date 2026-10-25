# frozen_string_literal: true

class ImportacaoFinanceira < ApplicationRecord
  self.table_name = "importacoes_financeiras"

  STATUS = %w[pendente concluida falha].freeze

  has_many :lancamentos_caixa, dependent: :nullify

  validates :checksum, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUS }

  serialize :relatorio, coder: JSON

  scope :concluidas, -> { where(status: "concluida") }

  def concluida?
    status == "concluida"
  end
end
