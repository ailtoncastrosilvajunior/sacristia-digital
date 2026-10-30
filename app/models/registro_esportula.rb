# frozen_string_literal: true

class RegistroEsportula < ApplicationRecord
  belongs_to :sacerdote
  belongs_to :evento_escala, optional: true
  belongs_to :lote_pagamento_esportula, optional: true
  has_one :lancamento_caixa, dependent: :nullify

  STATUS = %w[pendente pago].freeze

  validates :data, presence: true
  validates :valor, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUS }

  scope :pendentes, -> { where(status: "pendente") }
  scope :pagos, -> { where(status: "pago") }
  scope :por_competencia, ->(ano, mes) { where(competencia_ano: ano, competencia_mes: mes) }

  def self.para_evento(evento)
    find_by(evento_escala_id: evento.id)
  end

  # Cria ou atualiza o registro vinculado ao evento da escala (controle de pagamento).
  def self.sync_pago_from_evento!(evento, pago:)
    raise ArgumentError, "Evento sem sacerdote" if evento.sacerdote_id.blank?

    comp = evento.competencia_mensal
    reg = find_or_initialize_by(evento_escala_id: evento.id)
    reg.assign_attributes(
      sacerdote_id: evento.sacerdote_id,
      data: evento.data,
      valor: evento.valor_esportula.to_d,
      competencia_ano: comp.ano,
      competencia_mes: comp.mes,
      status: pago ? "pago" : "pendente"
    )
    reg.save!
    Financeiro::EsportulaLancamentoService.sync_from_registro!(reg)
    reg
  end

  # Atualiza sacerdote/valor/data do registro já existente quando o evento é editado (mantém status).
  def self.sync_from_evento!(evento)
    reg = find_by(evento_escala_id: evento.id)
    return unless reg
    return if evento.sacerdote_id.blank?

    comp = evento.competencia_mensal
    reg.update!(
      sacerdote_id: evento.sacerdote_id,
      data: evento.data,
      valor: evento.valor_esportula.to_d,
      competencia_ano: comp.ano,
      competencia_mes: comp.mes
    )
    Financeiro::EsportulaLancamentoService.sync_from_registro!(reg) if reg.status == "pago"
  end
end
