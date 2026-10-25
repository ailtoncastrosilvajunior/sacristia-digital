# frozen_string_literal: true

class PlanoConta < ApplicationRecord
  self.table_name = "plano_contas"

  include Financeiro::Auditavel

  NATUREZAS = %w[receita despesa].freeze

  belongs_to :conta_pai, class_name: "PlanoConta", optional: true
  has_many :subcontas, class_name: "PlanoConta", foreign_key: :conta_pai_id, dependent: :restrict_with_error
  has_many :itens_lancamento, dependent: :restrict_with_error

  validates :codigo, presence: true, uniqueness: true
  validates :nome, presence: true
  validates :natureza, inclusion: { in: NATUREZAS }

  scope :ativas, -> { where(ativo: true) }
  scope :analiticas, -> { where(sintetica: false) }
  scope :por_natureza, ->(n) { where(natureza: n) }
  scope :ordenadas, -> { order(:codigo) }

  def receita?
    natureza == "receita"
  end

  def despesa?
    natureza == "despesa"
  end

  def label_completo
    "#{codigo} — #{nome}"
  end
end
