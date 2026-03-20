# frozen_string_literal: true

class Sacerdote < ApplicationRecord
  has_many :calendario_base, dependent: :nullify
  has_many :evento_escalas, dependent: :nullify
  has_many :registro_esportulas, dependent: :destroy

  FORMAS_ESPORTULA = %w[por_missa por_periodo].freeze

  validates :nome, presence: true
  validates :forma_esportula, inclusion: { in: FORMAS_ESPORTULA }
  validates :valor_esportula_padrao, numericality: { greater_than_or_equal_to: 0 }

  scope :ativos, -> { where(ativo: true) }
  scope :ordenados_por_nome, -> { order(:nome) }

  def por_missa?
    forma_esportula == "por_missa"
  end

  def por_periodo?
    forma_esportula == "por_periodo"
  end
end
