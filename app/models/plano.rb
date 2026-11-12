# frozen_string_literal: true

class Plano < ApplicationRecord
  self.table_name = "planos"

  serialize :recursos, type: Hash, coder: JSON

  RECURSOS_PADRAO = %w[
    escala_mesc
    liturgia_cartaz
    esportulas
    financeiro_caixa
    escala_extra
    painel_sacerdote
  ].freeze

  RECURSOS_COMPLETO = RECURSOS_PADRAO.index_with { true }.freeze

  RECURSOS_ESCALA_LITURGIA = RECURSOS_PADRAO.index_with do |chave|
    chave.in?(%w[escala_mesc liturgia_cartaz])
  end.freeze

  has_many :instituicao_planos, dependent: :restrict_with_error

  validates :codigo, presence: true, uniqueness: true
  validates :nome, presence: true
  validates :preco_mensal_centavos, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  def recurso?(chave)
    mapa = recursos.is_a?(Hash) ? recursos : {}
    ActiveModel::Type::Boolean.new.cast(mapa.fetch(chave.to_s, false))
  end

  def self.completo!
    find_by!(codigo: "completo")
  end
end
