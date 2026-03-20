# frozen_string_literal: true

class RegistroEsportula < ApplicationRecord
  belongs_to :sacerdote
  belongs_to :evento_escala, optional: true

  STATUS = %w[pendente pago].freeze

  validates :data, presence: true
  validates :valor, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUS }

  scope :pendentes, -> { where(status: "pendente") }
  scope :pagos, -> { where(status: "pago") }
  scope :por_competencia, ->(ano, mes) { where(competencia_ano: ano, competencia_mes: mes) }
end
