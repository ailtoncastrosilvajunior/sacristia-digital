# frozen_string_literal: true

require "rails_helper"

RSpec.describe Financeiro::ResumoPeriodosService do
  before do
    Financeiro::PlanoContaSeedService.call
    @conta = ContaCorrente.padrao
    @receita = PlanoConta.find_by!(codigo: "1.1")
    @despesa = PlanoConta.find_by!(codigo: "2.1")
  end

  it "agrega meses com os mesmos totais do extrato" do
    LancamentoCaixa.create!(
      conta_corrente: @conta, natureza: "entrada", data: Date.new(2026, 1, 8), status: "confirmado",
      itens_lancamento_attributes: [{ plano_conta_id: @receita.id, quantidade: 1, preco_unitario: 100, valor: 100 }]
    )
    LancamentoCaixa.create!(
      conta_corrente: @conta, natureza: "saida", data: Date.new(2026, 2, 3), status: "confirmado",
      itens_lancamento_attributes: [{ plano_conta_id: @despesa.id, quantidade: 1, preco_unitario: 40, valor: 40 }]
    )

    resumo = described_class.new(ano: 2026)
    jan = resumo.periodos.find { |p| p.mes == 1 }
    fev = resumo.periodos.find { |p| p.mes == 2 }

    extrato_jan = ExtratoContaCorrenteService.new(@conta, de: Date.new(2026, 1, 1), ate: Date.new(2026, 1, 31).end_of_month)
    extrato_fev = ExtratoContaCorrenteService.new(@conta, de: Date.new(2026, 2, 1), ate: Date.new(2026, 2, 28).end_of_month)

    expect(jan.entradas).to eq(extrato_jan.totais_periodo[:entradas])
    expect(jan.saldo_final).to eq(extrato_jan.saldo_atual)
    expect(fev.saidas).to eq(extrato_fev.totais_periodo[:saidas])
    expect(fev.saldo_final).to eq(extrato_fev.saldo_atual)
  end
end
