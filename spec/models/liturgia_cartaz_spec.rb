# frozen_string_literal: true

require "rails_helper"

RSpec.describe LiturgiaCartaz do
  let(:inst_a) { Instituicao.find_by!(slug: "facedecristo") }
  let(:inst_b) do
    Instituicao.find_by(slug: "saovicente") ||
      Instituicao.create!(
        slug: "saovicente-spec",
        nome: "Spec B",
        ativa: true,
        assinatura_status: "ativa",
        tipo: "comunidade"
      )
  end
  let!(:liturgia) { LiturgiaDia.create!(data: Date.new(2099, 12, 25), status: "validada", titulo: "Teste") }

  it "permite um cartaz por instituição e dia litúrgico" do
    Current.instituicao = inst_a
    a = described_class.create!(instituicao: inst_a, liturgia_dia: liturgia)
    Current.instituicao = inst_b
    b = described_class.create!(instituicao: inst_b, liturgia_dia: liturgia)

    expect(a.liturgia_dia_id).to eq(b.liturgia_dia_id)
    expect(a.instituicao_id).not_to eq(b.instituicao_id)
  end

  it "expõe anexo via LiturgiaDia#cartaz_whatsapp_instituicao" do
    Current.instituicao = inst_a
    registro = described_class.create!(instituicao: inst_a, liturgia_dia: liturgia)
    registro.cartaz_whatsapp.attach(
      io: StringIO.new("fake"),
      filename: "test.png",
      content_type: "image/png"
    )

    expect(liturgia.cartaz_whatsapp_instituicao_attached?).to be(true)

    Current.instituicao = inst_b
    expect(liturgia.cartaz_whatsapp_instituicao_attached?).to be(false)
  end
end
