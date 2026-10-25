# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExtratoContaCorrenteService do
  before do
    Financeiro::PlanoContaSeedService.call
    @conta = ContaCorrente.padrao
    @receita = PlanoConta.find_by!(codigo: "1.1")
    @despesa = PlanoConta.find_by!(codigo: "2.1")
  end

  it "calcula saldo anterior e saldo após movimentos" do
    inicio = Date.new(2026, 1, 1)
    LancamentoCaixa.create!(
      conta_corrente: @conta, natureza: "entrada", data: Date.new(2026, 1, 5), status: "confirmado",
      itens_lancamento_attributes: [{ plano_conta_id: @receita.id, quantidade: 1, preco_unitario: 100, valor: 100 }]
    )
    LancamentoCaixa.create!(
      conta_corrente: @conta, natureza: "saida", data: Date.new(2026, 1, 10), status: "confirmado",
      itens_lancamento_attributes: [{ plano_conta_id: @despesa.id, quantidade: 1, preco_unitario: 40, valor: 40 }]
    )

    extrato = described_class.new(@conta, de: inicio, ate: inicio.end_of_month)
    expect(extrato.linhas.size).to eq(2)
    expect(extrato.saldo_atual).to eq(60)

    grupos = extrato.grupos_por_dia
    expect(grupos.size).to eq(2)
    expect(grupos.map(&:data)).to eq([Date.new(2026, 1, 5), Date.new(2026, 1, 10)])
    expect(grupos.first.total_entradas).to eq(100)
    expect(grupos.first.total_saidas).to eq(0)
    expect(grupos.last.total_saidas).to eq(40)
    expect(grupos.last.saldo_final).to eq(60)
  end
end
