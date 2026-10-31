# frozen_string_literal: true

require "rails_helper"

RSpec.describe Liturgia::CartazBriefing do
  it "inclui data e escala no texto" do
    ld = instance_double(
      LiturgiaDia,
      data: Date.new(2026, 10, 31),
      titulo: "30ª Semana do Tempo Comum",
      cor: "Verde",
      santo_nome: "Santo Exemplo",
      santo_descricao: "Descrição",
      validada?: true
    )
    cartaz = instance_double(
      Liturgia::CartazBuilder,
      linhas_leitura: [],
      linhas_escala: [
        Liturgia::CartazBuilder::LinhaEscala.new(horario: "08:00", presidente: "Pe. A", ministros: %w[Ana])
      ],
      igmr_paragrafo: nil,
      igmr_numero: 51
    )
    allow(Liturgia::CartazBuilder).to receive(:build).and_return(cartaz)

    text = described_class.text(ld)
    expect(text).to include("31/10/2026")
    expect(text).to include("08:00 | Pe. A | Ana")
  end

  it "inclui referências das leituras sem trecho de texto" do
    ld = instance_double(
      LiturgiaDia,
      data: Date.new(2026, 10, 31),
      titulo: "Tempo Comum",
      cor: "Verde",
      santo_nome: "Santo",
      santo_descricao: "",
      validada?: true
    )
    cartaz = instance_double(
      Liturgia::CartazBuilder,
      linhas_leitura: [
        Liturgia::CartazBuilder::LinhaLeitura.new(rotulo: "1ª Leitura", referencia: "Fl 2,12-18", trecho: "Texto longo…")
      ],
      linhas_escala: [],
      igmr_paragrafo: nil,
      igmr_numero: 51
    )
    allow(Liturgia::CartazBuilder).to receive(:build).and_return(cartaz)

    text = described_class.text(ld)
    expect(text).to include("1ª Leitura: Fl 2,12-18")
    expect(text).not_to include("Trecho:")
    expect(text).not_to include("Texto longo")
  end
end
