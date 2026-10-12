# frozen_string_literal: true

# Ministro que se oferece para apoiar o plantão (escala extra) de um dia. Vale na hora, sem aprovação.
class OfertaApoio < ApplicationRecord
  STATUSES = %w[ativa cancelada].freeze

  belongs_to :ministro
  belongs_to :competencia_mensal

  validates :data, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :ministro_id, uniqueness: { scope: :data }
  validate :data_dentro_da_competencia

  scope :ativas, -> { where(status: "ativa") }

  def ativa?
    status == "ativa"
  end

  def cancelar!
    update!(status: "cancelada")
  end

  private

  def data_dentro_da_competencia
    return if data.blank? || competencia_mensal.blank?

    errors.add(:data, "fora do mês da escala") unless data.between?(competencia_mensal.periodo, competencia_mensal.periodo_fim)
  end
end
