# frozen_string_literal: true

class InstituicaoPlano < ApplicationRecord
  self.table_name = "instituicao_planos"

  serialize :recursos_snapshot, type: Hash, coder: JSON

  STATUSES = %w[agendada vigente encerrada].freeze

  belongs_to :instituicao
  belongs_to :plano

  validates :vigencia_inicio, :modulos_vigencia_inicio, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :preco_mensal_centavos, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :vigencia_fim_posterior_inicio

  scope :vigentes, -> { where(status: "vigente", vigencia_fim: nil) }
  scope :ordenados, -> { order(vigencia_inicio: :desc) }

  def recurso?(chave)
    mapa = recursos_snapshot.presence || plano.recursos
    mapa = mapa.is_a?(Hash) ? mapa : {}
    ActiveModel::Type::Boolean.new.cast(mapa.fetch(chave.to_s, false))
  end

  private

  def vigencia_fim_posterior_inicio
    return if vigencia_fim.blank?

    errors.add(:vigencia_fim, :invalid) if vigencia_fim <= vigencia_inicio
  end
end
