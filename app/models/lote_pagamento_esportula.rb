# frozen_string_literal: true

class LotePagamentoEsportula < ApplicationRecord
  belongs_to :competencia_mensal
  belongs_to :destinatario_esportula, optional: true
  belongs_to :destinatario_sacerdote, class_name: "Sacerdote", optional: true
  has_many :lote_pagamento_esportula_eventos, dependent: :destroy
  has_many :evento_escalas, through: :lote_pagamento_esportula_eventos
  has_many :registro_esportulas, dependent: :nullify
  has_one :lancamento_caixa, dependent: :nullify

  DESTINATARIO_TIPOS = %w[instituicao sacerdote].freeze
  STATUS = %w[pendente pago].freeze

  validates :destinatario_tipo, inclusion: { in: DESTINATARIO_TIPOS }
  validates :status, inclusion: { in: STATUS }
  validates :valor, numericality: { greater_than_or_equal_to: 0 }
  validate :destinatario_presente

  scope :pagos, -> { where(status: "pago") }

  def instituicao?
    destinatario_tipo == "instituicao"
  end

  def nome_destinatario
    if instituicao?
      destinatario_esportula&.nome
    else
      destinatario_sacerdote&.nome
    end
  end

  def pago?
    status == "pago"
  end

  private

  def destinatario_presente
    if instituicao? && destinatario_esportula_id.blank?
      errors.add(:destinatario_esportula, "é obrigatório para pagamento à instituição")
    elsif destinatario_tipo == "sacerdote" && destinatario_sacerdote_id.blank?
      errors.add(:destinatario_sacerdote, "é obrigatório")
    end
  end
end
