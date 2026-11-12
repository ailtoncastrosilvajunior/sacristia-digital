# frozen_string_literal: true

class Instituicao < ApplicationRecord
  self.table_name = "instituicoes"

  ASSINATURA_STATUSES = %w[trial ativa suspensa].freeze

  enum :tipo, { comunidade: "comunidade", paroquia: "paroquia" }, validate: true

  has_many :instituicao_planos, dependent: :destroy
  has_many :planos, through: :instituicao_planos

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :nome, presence: true
  validates :assinatura_status, inclusion: { in: ASSINATURA_STATUSES }

  scope :ativas, -> { where(ativa: true) }

  def instituicao_plano_vigente
    instituicao_planos.vigentes.order(vigencia_inicio: :desc).first
  end

  def plano_catalogo
    instituicao_plano_vigente&.plano
  end

  def recurso?(chave)
    return false unless ativa?

    instituicao_plano_vigente&.recurso?(chave) || false
  end

  def nome_exibicao_recibos
    nome_recibos.presence || nome
  end

  def self.find_by_host!(slug)
    ativas.find_by!(slug: slug.to_s.downcase)
  end
end
