# frozen_string_literal: true

require "rails_helper"

RSpec.describe Esportulas::ConferenciaMesService do
  before { Financeiro::PlanoContaSeedService.call }

  let(:competencia) { CompetenciaMensal.para_mes(2099, 1) }
  let(:sacerdote) { Sacerdote.create!(nome: "Pe. Conf", valor_esportula_padrao: 100) }
  let(:tipo) { TipoServico.create!(nome: "Missa", tipo_escala: "ordinaria") }
  let(:conta_21) { PlanoConta.find_by!(codigo: "2.1") }

  it "monta imediato por dia e totais do mês" do
    dia = Date.new(2099, 1, 10)
    EventoEscala.create!(
      competencia_mensal: competencia,
      tipo_servico: tipo,
      sacerdote: sacerdote,
      data: dia,
      horario: "19:00",
      valor_esportula: 150,
      tipo_escala: "ordinaria",
      status: "confirmado",
      quantidade_ministros: 0
    )

    result = described_class.call(competencia)
    im = result[:imediato]
    expect(im[:dias].map(&:day)).to include(10)
    expect(result[:totais][:previsto]).to eq(150)
    expect(im[:linhas].size).to eq(4)
    previsto = im[:linhas].find { |l| l.key == :previsto }
    expect(previsto.valores_por_dia[dia]).to eq(150)

    delta = im[:linhas].find { |l| l.key == :delta }
    expect(delta.valores_por_dia[dia]).to eq(-150)
    expect(result[:totais][:delta_mes]).to eq(-150)
  end

  it "2.1 imediato soma todos os LC 2.1 do dia, mesmo sem registro vinculado" do
    dia = Date.new(2099, 1, 1)
    2.times do |i|
      EventoEscala.create!(
        competencia_mensal: competencia,
        tipo_servico: tipo,
        sacerdote: sacerdote,
        data: dia,
        horario: format("%02d:00", 10 + i),
        valor_esportula: 150,
        tipo_escala: "ordinaria",
        status: "confirmado",
        quantidade_ministros: 0
      )
    end
    2.times do
      LancamentoCaixa.create!(
        conta_corrente: ContaCorrente.padrao,
        natureza: "saida",
        data: dia,
        status: "confirmado",
        itens_lancamento_attributes: [
          { plano_conta_id: conta_21.id, quantidade: 1, preco_unitario: 150, valor: 150 }
        ]
      )
    end

    caixa = described_class.call(competencia)[:imediato][:linhas].find { |l| l.key == :caixa_21 }
    expect(caixa.valores_por_dia[dia]).to eq(300)
  end

  it "Δ imediato no dia é caixa 2.1 vinculado menos previsto" do
    dia = Date.new(2099, 1, 15)
    evento = EventoEscala.create!(
      competencia_mensal: competencia,
      tipo_servico: tipo,
      sacerdote: sacerdote,
      data: dia,
      horario: "19:00",
      valor_esportula: 400,
      tipo_escala: "ordinaria",
      status: "confirmado",
      quantidade_ministros: 0
    )
    lc = LancamentoCaixa.create!(
      conta_corrente: ContaCorrente.padrao,
      natureza: "saida",
      data: dia,
      status: "confirmado",
      itens_lancamento_attributes: [
        { plano_conta_id: conta_21.id, quantidade: 1, preco_unitario: 300, valor: 300 }
      ]
    )
    reg = RegistroEsportula.create!(
      sacerdote: sacerdote,
      evento_escala: evento,
      data: dia,
      valor: 400,
      status: "pago",
      competencia_ano: 2099,
      competencia_mes: 1
    )
    lc.update!(registro_esportula: reg)

    delta = described_class.call(competencia)[:imediato][:linhas].find { |l| l.key == :delta }
    expect(delta.valores_por_dia[dia]).to eq(-100)
  end

  it "acumulado agrega previsto, pago e caixa do lote no mês" do
    dia_evento = Date.new(2099, 1, 5)
    dia_caixa = Date.new(2099, 1, 28)
    evento = EventoEscala.create!(
      competencia_mensal: competencia,
      tipo_servico: tipo,
      sacerdote: sacerdote,
      data: dia_evento,
      horario: "10:00",
      valor_esportula: 300,
      esportula_modo: "acumulado",
      tipo_escala: "ordinaria",
      status: "confirmado",
      quantidade_ministros: 0
    )
    lote = LotePagamentoEsportula.create!(
      competencia_mensal: competencia,
      destinatario_tipo: "sacerdote",
      destinatario_sacerdote: sacerdote,
      valor: 300,
      data_pagamento: dia_caixa,
      status: "pago"
    )
    RegistroEsportula.create!(
      sacerdote: sacerdote,
      evento_escala: evento,
      data: dia_evento,
      valor: 300,
      status: "pago",
      competencia_ano: 2099,
      competencia_mes: 1,
      lote_pagamento_esportula: lote
    )

    ac = described_class.call(competencia)[:acumulado]
    expect(ac.previsto).to eq(300)
    expect(ac.pago).to eq(300)
    expect(ac.caixa_21).to eq(0)
    expect(ac.delta).to eq(-300)

    im = described_class.call(competencia)[:imediato]
    pago_im = im[:linhas].find { |l| l.key == :pago }
    expect(pago_im.valores_por_dia[dia_evento]).to eq(0)
    expect(pago_im.valores_por_dia[dia_caixa]).to eq(0)

    Financeiro::EsportulaLancamentoService.sync_from_lote!(lote)
    ac2 = described_class.call(competencia)[:acumulado]
    expect(ac2.caixa_21).to eq(300)
    expect(ac2.delta).to eq(0)
  end
end
