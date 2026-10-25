# frozen_string_literal: true

require "rails_helper"

RSpec.describe Financeiro::EsportulaLancamentoService do
  before { Financeiro::PlanoContaSeedService.call }

  let(:sacerdote) { Sacerdote.create!(nome: "Pe. Teste", valor_esportula_padrao: 150) }
  let(:competencia) { CompetenciaMensal.para_mes(2025, 6) }
  let(:tipo) { TipoServico.create!(nome: "Missa", tipo_escala: "ordinaria") }
  let(:evento) do
    EventoEscala.create!(
      competencia_mensal: competencia,
      tipo_servico: tipo,
      sacerdote: sacerdote,
      data: Date.new(2025, 6, 15),
      horario: "19:00",
      valor_esportula: 150,
      tipo_escala: "ordinaria",
      status: "confirmado",
      quantidade_ministros: 0
    )
  end
  let(:registro) do
    RegistroEsportula.create!(
      sacerdote: sacerdote,
      evento_escala: evento,
      data: evento.data,
      valor: 150,
      status: "pago",
      competencia_ano: 2025,
      competencia_mes: 6
    )
  end

  it "cria lançamento de saída vinculado ao evento e registro" do
    lc = described_class.sync_from_registro!(registro)
    expect(lc).to be_persisted
    expect(lc.natureza).to eq("saida")
    expect(lc.evento_escala_id).to eq(evento.id)
    expect(lc.registro_esportula_id).to eq(registro.id)
    expect(lc.fornecedor).to eq("Pe. Teste")
    expect(lc.itens_lancamento.first.plano_conta.codigo).to eq("2.1")
  end

  it "remove o lançamento ao desmarcar pagamento" do
    described_class.sync_from_registro!(registro)
    registro.update!(status: "pendente")

    expect { described_class.sync_from_registro!(registro) }.to change(LancamentoCaixa, :count).by(-1)
    expect(LancamentoCaixa.find_by(registro_esportula_id: registro.id)).to be_nil
  end

  it "não exclui lançamento ao desmarcar se não estiver vinculado ao evento" do
    lc = described_class.sync_from_registro!(registro)
    lc.update!(evento_escala_id: nil)
    registro.update!(status: "pendente")

    expect { described_class.sync_from_registro!(registro) }.not_to change(LancamentoCaixa, :count)
    expect(lc.reload).to be_persisted
  end

  it "integra com sync_pago_from_evento!" do
    expect {
      RegistroEsportula.sync_pago_from_evento!(evento, pago: true)
    }.to change(LancamentoCaixa, :count).by(1)

    expect {
      RegistroEsportula.sync_pago_from_evento!(evento, pago: false)
    }.to change(LancamentoCaixa, :count).by(-1)
  end
end
