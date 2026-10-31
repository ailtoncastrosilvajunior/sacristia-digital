# frozen_string_literal: true

require "rails_helper"

RSpec.describe Liturgia::BriefingChecklist do
  let(:data) { Date.new(2026, 11, 4) }

  def liturgia_double(validada: true, santo: "São Carlos", leituras: [{ "tipo" => "evangelho" }], imagem: false)
    instance_double(
      LiturgiaDia,
      validada?: validada,
      santo_nome: santo,
      leituras: leituras,
      imagem_santo: instance_double(ActiveStorage::Attached::One, attached?: imagem),
      data: data
    )
  end

  before do
    allow(Liturgia::CartazBuilder).to receive(:build).and_return(cartaz)
  end

  context "sem IGMR cadastrada" do
    let(:cartaz) do
      instance_double(
        Liturgia::CartazBuilder,
        igmr_numero: 55,
        igmr_paragrafo: nil,
        linhas_escala: []
      )
    end

    it "bloqueia o briefing" do
      checklist = described_class.new(liturgia_double)
      expect(checklist.briefing_liberado?).to be false
      igmr = checklist.items.find { |i| i.id == :igmr }
      expect(igmr.bloqueia).to be true
      expect(igmr.ok).to be false
    end
  end

  context "com IGMR cadastrada" do
    let(:paragrafo) { instance_double(IgmrParagrafo, numero: 55) }
    let(:cartaz) do
      instance_double(
        Liturgia::CartazBuilder,
        igmr_numero: 55,
        igmr_paragrafo: paragrafo,
        linhas_escala: [Liturgia::CartazBuilder::LinhaEscala.new(horario: "07:00", presidente: "Pe.", ministros: [])]
      )
    end

    it "libera o briefing" do
      checklist = described_class.new(liturgia_double(imagem: true))
      expect(checklist.briefing_liberado?).to be true
    end
  end
end
