# frozen_string_literal: true

module Esportulas
  # Monta os dados de um ou mais recibos de espórtula na competência.
  class ReciboDados
    Recibo = Struct.new(:sacerdote, :linha, :eventos, keyword_init: true)

    def self.call(competencia:, sacerdote_id: nil, eventos: nil, evento_escala_ids: nil)
      new(competencia:, sacerdote_id:, eventos:, evento_escala_ids:).call
    end

    def initialize(competencia:, sacerdote_id: nil, eventos: nil, evento_escala_ids: nil)
      @competencia = competencia
      @sacerdote_id = sacerdote_id.presence
      @eventos = eventos
      @evento_escala_ids = Array(evento_escala_ids).map(&:to_i).reject(&:zero?).presence
    end

    def call
      eventos = (@eventos || eventos_da_competencia).dup
      eventos.select! { |e| @evento_escala_ids.include?(e.id) } if @evento_escala_ids
      eventos.select! { |e| e.sacerdote_id == @sacerdote_id.to_i } if @sacerdote_id
      eventos.select! { |e| e.sacerdote.present? }

      eventos.sort_by { |e| [e.data, e.horario] }.filter_map do |ev|
        sacerdote = ev.sacerdote
        linha = linha_de_eventos([ev])
        next if linha[:previsto].to_d.zero?

        Recibo.new(sacerdote:, linha:, eventos: [ev])
      end
    end

    private

    def linha_de_eventos(eventos)
      previsto = eventos.sum { |e| e.valor_esportula.to_d }
      realizado = eventos.select(&:esportula_paga?).sum { |e| e.valor_esportula.to_d }
      missas = eventos.count { |e| e.tipo_servico.nome.to_s.match?(/missa/i) }
      confissoes = eventos.count { |e| e.tipo_servico.nome.to_s.match?(/confiss/i) }
      {
        missas: missas,
        confissoes: confissoes,
        total_servicos: eventos.size,
        previsto: previsto,
        previsto_imediato: eventos.select(&:esportula_imediato?).sum { |e| e.valor_esportula.to_d },
        realizado: realizado,
        saldo: previsto - realizado
      }
    end

    def eventos_da_competencia
      @competencia.evento_escalas
        .ordinarios
        .nao_cancelados
        .includes(:tipo_servico, :sacerdote, registro_esportulas: :lote_pagamento_esportula)
        .order(:data, :horario)
        .to_a
        .select { |e| e.valor_esportula.to_d.positive? && e.sacerdote_id.present? }
    end
  end
end
