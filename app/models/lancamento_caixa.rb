# frozen_string_literal: true

class LancamentoCaixa < ApplicationRecord
  self.table_name = "lancamentos_caixa"

  include Financeiro::Auditavel

  NATUREZAS = %w[entrada saida].freeze
  STATUS = %w[confirmado estornado].freeze

  belongs_to :conta_corrente
  belongs_to :evento_escala, optional: true
  belongs_to :registro_esportula, optional: true
  belongs_to :lote_pagamento_esportula, optional: true
  belongs_to :importacao_financeira, optional: true

  has_many :itens_lancamento, -> { order(:ordem, :id) },
           class_name: "ItemLancamento", dependent: :destroy, inverse_of: :lancamento_caixa

  accepts_nested_attributes_for :itens_lancamento, allow_destroy: true, reject_if: :rejeitar_item_vazio?

  validates :natureza, inclusion: { in: NATUREZAS }
  validates :status, inclusion: { in: STATUS }
  validates :data, presence: true
  validates :valor_total, numericality: { greater_than_or_equal_to: 0 }
  validate :itens_compativeis_com_natureza
  validate :conta_analitica_nos_itens

  scope :confirmados, -> { where(status: "confirmado") }
  scope :no_periodo, ->(de, ate) { where(data: de..ate) }
  scope :entradas, -> { where(natureza: "entrada") }
  scope :saidas, -> { where(natureza: "saida") }

  before_validation :recalcular_valor_total

  def entrada?
    natureza == "entrada"
  end

  def saida?
    natureza == "saida"
  end

  def estornado?
    status == "estornado"
  end

  def estornar!(user: nil)
    return if estornado?

    update!(status: "estornado")
    registrar_auditoria!("estornar", user: user)
  end

  def valor_com_sinal
    entrada? ? valor_total.to_d : -valor_total.to_d
  end

  private

  def rejeitar_item_vazio?(attrs)
    attrs["plano_conta_id"].blank? && attrs["valor"].blank? && attrs["descricao"].blank?
  end

  def recalcular_valor_total
    itens = itens_lancamento.reject(&:marked_for_destruction?)
    return if itens.empty?

    # Usa qtd × preço − desconto (não item.valor), pois o before_validation do pai
    # roda antes do calcular_valor dos itens aninhados.
    self.valor_total = itens.sum { |i| ItemLancamento.valor_liquido(i) }
  end

  def itens_compativeis_com_natureza
    itens_lancamento.reject(&:marked_for_destruction?).each do |item|
      next if item.plano_conta.blank?

      if entrada? && !item.plano_conta.receita?
        item.errors.add(:plano_conta, "deve ser conta de receita")
        errors.add(:base, "Itens de entrada devem usar contas de receita")
      elsif saida? && !item.plano_conta.despesa?
        item.errors.add(:plano_conta, "deve ser conta de despesa")
        errors.add(:base, "Itens de saída devem usar contas de despesa")
      end
    end
  end

  def conta_analitica_nos_itens
    itens_lancamento.reject(&:marked_for_destruction?).each do |item|
      next if item.plano_conta.blank?
      next unless item.plano_conta.sintetica?

      item.errors.add(:plano_conta, "não pode ser sintética")
      errors.add(:base, "Use contas analíticas nos itens")
    end
  end
end
