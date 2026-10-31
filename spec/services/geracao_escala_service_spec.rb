# frozen_string_literal: true

require "rails_helper"

RSpec.describe GeracaoEscalaService do
  let(:competencia) { CompetenciaMensal.find_or_create_by!(ano: 2098, mes: 3) }
  let(:instituicao) { DestinatarioEsportula.create!(nome: "Eudistas Spec Geração") }
  let(:titular) { Sacerdote.create!(nome: "Pe. Titular Geração", forma_esportula: "por_missa", valor_esportula_padrao: 100) }

  before do
    TipoServico.find_or_create_by!(nome: "Missa") { |t| t.assign_attributes(tipo_escala: "ordinaria", cor_etiqueta: "#2563eb", ativo: true) }
    CalendarioBase.where(dia_da_semana: 0).destroy_all
    CalendarioBase.create!(
      dia_da_semana: 0,
      horario: "09:00",
      tipo: "missa",
      sacerdote: titular,
      esportula_modo: "acumulado",
      destinatario_esportula: instituicao,
      quantidade_ministros: 0,
      ativo: true
    )
  end

  it "copia modo e instituição do calendário base ao gerar eventos" do
    competencia.evento_escalas.ordinarios.destroy_all
    criados = described_class.new(competencia).gerar!(modo: "substituir")

    expect(criados).to be >= 1
    evento = competencia.evento_escalas.ordinarios.find_by!(horario: "09:00")
    expect(evento.calendario_base_id).to be_present
    expect(evento.esportula_modo).to eq("acumulado")
    expect(evento.destinatario_esportula_id).to eq(instituicao.id)
    expect(evento.esportula_destinatario_tipo).to eq("instituicao")
  end
end
