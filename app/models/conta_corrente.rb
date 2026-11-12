# frozen_string_literal: true

class ContaCorrente < ApplicationRecord
  include InstituicaoScoped

  self.table_name = "contas_correntes"

  has_many :lancamentos_caixa, class_name: "LancamentoCaixa", dependent: :restrict_with_error

  validates :nome, presence: true
  validates :data_saldo_inicial, presence: true
  validates :saldo_inicial, numericality: true

  scope :ativas, -> { where(ativo: true) }

  def self.padrao
    scope = da_instituicao_atual.ativas.order(:id)
    scope.first || scope.create!(
      nome: "Caixa Sacristia",
      saldo_inicial: 0,
      data_saldo_inicial: Date.new(2020, 1, 1)
    )
  end
end
