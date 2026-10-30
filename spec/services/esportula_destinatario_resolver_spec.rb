# frozen_string_literal: true

require "rails_helper"

RSpec.describe EsportulaDestinatarioResolver do
  let(:competencia) { CompetenciaMensal.find_or_create_by!(ano: 2099, mes: 1) }
  let(:tipo) { TipoServico.find_or_create_by!(nome: "Missa Spec Resolver") { |t| t.assign_attributes(tipo_escala: "ordinaria", cor_etiqueta: "#000", ativo: true) } }
  let(:instituicao) { DestinatarioEsportula.create!(nome: "Padres Eudistas") }
  let(:titular) { Sacerdote.create!(nome: "Pe. Eudista", forma_esportula: "por_missa", valor_esportula_padrao: 150) }
  let(:substituto) { Sacerdote.create!(nome: "Pe. Substituto", forma_esportula: "por_missa", valor_esportula_padrao: 150) }
  let(:mensal) { Sacerdote.create!(nome: "Msgr. Mensal", forma_esportula: "por_periodo", valor_esportula_padrao: 150) }

  let(:calendario) do
    CalendarioBase.create!(
      dia_da_semana: 1,
      horario: "12:10",
      tipo: "missa",
      sacerdote: titular,
      esportula_modo: "acumulado",
      destinatario_esportula: instituicao
    )
  end

  def build_evento(sacerdote:, calendario_base: calendario)
    EventoEscala.create!(
      competencia_mensal: competencia,
      tipo_servico: tipo,
      data: Date.new(2099, 1, 5),
      horario: "12:10",
      sacerdote: sacerdote,
      valor_esportula: 150,
      calendario_base: calendario_base,
      quantidade_ministros: 0,
      tipo_escala: "ordinaria",
      status: "confirmado"
    )
  end

  it "acumula para instituição quando titular no slot" do
    evento = build_evento(sacerdote: titular)
    described_class.apply!(evento, calendario_base: calendario)

    expect(evento.esportula_modo).to eq("acumulado")
    expect(evento.destinatario_esportula_id).to eq(instituicao.id)
  end

  it "imediato para substituto no slot institucional" do
    evento = build_evento(sacerdote: substituto)
    described_class.apply!(evento, calendario_base: calendario)

    expect(evento.esportula_modo).to eq("imediato")
    expect(evento.esportula_destinatario_sacerdote_id).to eq(substituto.id)
  end

  it "acumula para o próprio sacerdote por_periodo" do
    evento = build_evento(sacerdote: mensal, calendario_base: nil)
    described_class.apply!(evento)

    expect(evento.esportula_modo).to eq("acumulado")
    expect(evento.esportula_destinatario_sacerdote_id).to eq(mensal.id)
  end
end
