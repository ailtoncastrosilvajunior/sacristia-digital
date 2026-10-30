# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotePagamentoEsportulaService do
  before { Financeiro::PlanoContaSeedService.call }

  let(:sacerdote) { Sacerdote.create!(nome: "Pe. Lote", valor_esportula_padrao: 100) }
  let(:competencia) { CompetenciaMensal.para_mes(2025, 8) }
  let(:tipo) { TipoServico.create!(nome: "Missa", tipo_escala: "ordinaria") }
  let(:evento) do
    EventoEscala.create!(
      competencia_mensal: competencia,
      tipo_servico: tipo,
      sacerdote: sacerdote,
      data: Date.new(2025, 8, 10),
      horario: "12:00",
      valor_esportula: 100,
      tipo_escala: "ordinaria",
      status: "confirmado",
      quantidade_ministros: 0,
      esportula_modo: "acumulado",
      esportula_destinatario_tipo: "sacerdote",
      esportula_destinatario_sacerdote: sacerdote
    )
  end

  describe ".registrar_pagamento! / .estornar_lote!" do
    it "estorna lote pago, remove caixa e deixa registros pendentes" do
      evento
      lote = described_class.registrar_pagamento!(
        competencia: competencia,
        destinatario_tipo: "sacerdote",
        destinatario_sacerdote: sacerdote,
        data_pagamento: Date.new(2025, 8, 31)
      )
      lote_id = lote.id
      expect(LancamentoCaixa.find_by(lote_pagamento_esportula_id: lote_id)).to be_present

      described_class.estornar_lote!(lote)

      expect(LotePagamentoEsportula.find_by(id: lote_id)).to be_nil
      expect(LancamentoCaixa.find_by(lote_pagamento_esportula_id: lote_id)).to be_nil
      reg = RegistroEsportula.find_by!(evento_escala_id: evento.id)
      expect(reg.status).to eq("pendente")
      expect(reg.lote_pagamento_esportula_id).to be_nil
      expect(evento.reload.esportula_paga_em_lote?).to be false
    end
  end

  describe ".desmarcar_evento!" do
    it "impede desmarcar evento pago em lote" do
      evento
      described_class.registrar_pagamento!(
        competencia: competencia,
        destinatario_tipo: "sacerdote",
        destinatario_sacerdote: sacerdote
      )

      expect {
        described_class.desmarcar_evento!(evento)
      }.to raise_error(ArgumentError, /lote/)
    end
  end
end
