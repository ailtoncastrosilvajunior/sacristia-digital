# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlantaoExtraCartaz do
  let(:competencia) { CompetenciaMensal.para_mes(2026, 7) }
  let(:plantao) do
    pp = competencia.plantao_periodos.create!(dia_inicio: 21, dia_fim: 22)
    pp
  end
  let(:tipo) { TipoServico.create!(nome: "Missa", tipo_escala: "extra", ativo: true) }

  it "agrupa eventos extras do período por dia" do
    EventoEscala.create!(
      competencia_mensal: competencia,
      plantao_periodo: plantao,
      tipo_servico: tipo,
      tipo_escala: "extra",
      data: Date.new(2026, 7, 21),
      horario: "19:30",
      local: "Capela grande",
      quantidade_ministros: 2
    )

    cartaz = described_class.build(plantao)
    expect(cartaz.dias.size).to eq(1)
    expect(cartaz.dias.first.eventos.size).to eq(1)
    expect(cartaz.periodo_rotulo).to include("21 e 22")
    expect(cartaz.periodo_rotulo).to include("JULHO")
  end

  it "ignora dias do plantão sem evento" do
    cartaz = described_class.build(plantao)
    expect(cartaz.vazio?).to be(true)
  end

  it "detecta sobreposição com o período visível na agenda" do
    periodo = Date.new(2026, 7, 20)..Date.new(2026, 7, 23)
    expect(plantao.sobrepoe_periodo?(periodo)).to be(true)
    expect(plantao.sobrepoe_periodo?(Date.new(2026, 7, 1)..Date.new(2026, 7, 10))).to be(false)
  end
end
