# frozen_string_literal: true

class EsportulasDestinatarioAcumuladoResumo
  Linha = Struct.new(
    :destinatario_tipo, :destinatario_esportula, :destinatario_sacerdote,
    :nome, :missas, :previsto, :realizado, :saldo, :lancamento_caixa, :lote_pagamento_esportula,
    keyword_init: true
  )

  def self.call(competencia)
    new(competencia).call
  end

  def initialize(competencia)
    @competencia = competencia
  end

  def call
    eventos = EventoEscala
      .where(competencia_mensal_id: @competencia.id)
      .nao_cancelados
      .where(esportula_modo: "acumulado")
      .where("evento_escala.valor_esportula > 0")
      .where.not(sacerdote_id: nil)
      .includes(
        :tipo_servico, :destinatario_esportula, :esportula_destinatario_sacerdote,
        registro_esportulas: [:lancamento_caixa, { lote_pagamento_esportula: :lancamento_caixa }]
      )

    grupos = eventos.group_by { |ev| chave(ev) }

    linhas = grupos.filter_map do |(_tipo, _id), evs|
      next if evs.empty?

      sample = evs.first
      previsto = evs.sum { |e| e.valor_esportula.to_d }
      realizado = evs.sum { |e| e.esportula_paga? ? e.valor_esportula.to_d : 0.to_d }
      saldo = previsto - realizado
      missas = evs.count { |e| e.tipo_servico.nome.to_s.match?(/missa/i) }
      lancamento = lancamento_caixa_acumulado(evs, saldo: saldo, previsto: previsto)
      lote = lote_pagamento_acumulado(evs, saldo: saldo, previsto: previsto)

      Linha.new(
        destinatario_tipo: sample.esportula_destinatario_tipo == "instituicao" ? "instituicao" : "sacerdote",
        destinatario_esportula: sample.destinatario_esportula,
        destinatario_sacerdote: sample.esportula_destinatario_sacerdote,
        nome: sample.esportula_destinatario_nome,
        missas: missas,
        previsto: previsto,
        realizado: realizado,
        saldo: saldo,
        lancamento_caixa: lancamento,
        lote_pagamento_esportula: lote
      )
    end

    linhas.sort_by { |l| l.nome.to_s.downcase }
  end

  private

  def chave(ev)
    ev.esportula_pagamento_chave_destinatario
  end

  def lancamento_caixa_acumulado(evs, saldo:, previsto:)
    return nil unless previsto.positive? && saldo.zero?

    evs.lazy.filter_map(&:esportula_lancamento_caixa).first
  end

  def lote_pagamento_acumulado(evs, saldo:, previsto:)
    return nil unless previsto.positive? && saldo.zero?

    evs.lazy.filter_map { |ev| ev.registro_esportula_vinculado&.lote_pagamento_esportula }.find(&:pago?)
  end
end
