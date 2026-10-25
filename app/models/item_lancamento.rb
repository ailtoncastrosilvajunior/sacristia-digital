# frozen_string_literal: true

class ItemLancamento < ApplicationRecord
  self.table_name = "itens_lancamento"

  include Financeiro::Auditavel

  belongs_to :lancamento_caixa, inverse_of: :itens_lancamento
  belongs_to :plano_conta

  validates :valor, numericality: { greater_than_or_equal_to: 0 }
  validates :valor_desconto, numericality: { greater_than_or_equal_to: 0 }
  validates :quantidade, numericality: { greater_than: 0 }, allow_nil: false
  validates :preco_unitario, numericality: true
  validate :desconto_nao_maior_que_bruto

  before_validation :calcular_valor

  def self.valor_liquido(item)
    q = item.quantidade.to_d
    p = item.preco_unitario.to_d
    d = item.valor_desconto.to_d
    bruto = (q * p).round(2)
    d = [d, bruto].min
    [(bruto - d).round(2), 0.to_d].max
  end

  private

  def calcular_valor
    self.valor = self.class.valor_liquido(self)
  end

  def desconto_nao_maior_que_bruto
    bruto = (quantidade.to_d * preco_unitario.to_d).round(2)
    return if valor_desconto.to_d <= bruto + 0.001

    errors.add(:valor_desconto, "não pode ser maior que qtd. × preço (#{bruto})")
  end
end
