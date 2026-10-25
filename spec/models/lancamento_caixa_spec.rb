# frozen_string_literal: true

require "rails_helper"

RSpec.describe LancamentoCaixa, type: :model do
  before do
    Financeiro::PlanoContaSeedService.call
    ContaCorrente.padrao
  end

  let(:conta_receita) { PlanoConta.find_by!(codigo: "1.1") }
  let(:conta_despesa) { PlanoConta.find_by!(codigo: "2.5.5") }
  let(:conta_corrente) { ContaCorrente.padrao }

  it "valida natureza da conta nos itens" do
    lanc = described_class.new(
      conta_corrente: conta_corrente,
      natureza: "entrada",
      data: Date.current,
      status: "confirmado",
      itens_lancamento_attributes: [
        { plano_conta_id: conta_despesa.id, quantidade: 1, preco_unitario: 10, valor: 10 }
      ]
    )
    expect(lanc).not_to be_valid
  end

  it "recalcula valor_total a partir dos itens" do
    lanc = described_class.create!(
      conta_corrente: conta_corrente,
      natureza: "saida",
      data: Date.current,
      status: "confirmado",
      itens_lancamento_attributes: [
        { plano_conta_id: conta_despesa.id, quantidade: 2, preco_unitario: 30, valor: 60 }
      ]
    )
    expect(lanc.valor_total).to eq(60)
  end
end
