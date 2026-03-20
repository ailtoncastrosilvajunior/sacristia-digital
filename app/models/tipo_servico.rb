# frozen_string_literal: true

class TipoServico < ApplicationRecord
  self.table_name = "tipo_servicos"

  has_many :evento_escalas, dependent: :restrict_with_error

  TIPOS_ESCALA = %w[ordinaria extra].freeze

  validates :nome, presence: true
  validates :tipo_escala, inclusion: { in: TIPOS_ESCALA }

  scope :ativos, -> { where(ativo: true) }
  scope :ordinarios, -> { where(tipo_escala: "ordinaria") }
  scope :extras, -> { where(tipo_escala: "extra") }

  def ordinario?
    tipo_escala == "ordinaria"
  end

  def extra?
    tipo_escala == "extra"
  end
end
