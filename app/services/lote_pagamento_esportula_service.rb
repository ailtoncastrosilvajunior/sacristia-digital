# frozen_string_literal: true

class LotePagamentoEsportulaService
  def self.desmarcar_evento!(evento)
    reg = RegistroEsportula.find_by(evento_escala_id: evento.id)
    return unless reg&.status == "pago"

    if reg.lote_pagamento_esportula_id.present?
      raise ArgumentError, "Espórtula paga em lote — estorne no card Destinatários acumulados."
    end

    RegistroEsportula.sync_pago_from_evento!(evento, pago: false)
  end

  def self.estornar_lote!(lote)
    raise ArgumentError, "Lote não está pago." unless lote.pago?

    LotePagamentoEsportula.transaction do
      lote.registro_esportulas.find_each do |reg|
        reg.update!(status: "pendente", lote_pagamento_esportula_id: nil)
      end
      lote.lancamento_caixa&.destroy!
      lote.destroy!
    end
  end

  def self.registrar_pagamento!(competencia:, destinatario_tipo:, destinatario_esportula: nil, destinatario_sacerdote: nil,
                                data_pagamento: Date.current, forma_pagamento: nil)
    new(
      competencia: competencia,
      destinatario_tipo: destinatario_tipo,
      destinatario_esportula: destinatario_esportula,
      destinatario_sacerdote: destinatario_sacerdote
    ).registrar_pagamento!(data_pagamento: data_pagamento, forma_pagamento: forma_pagamento)
  end

  def initialize(competencia:, destinatario_tipo:, destinatario_esportula: nil, destinatario_sacerdote: nil)
    @competencia = competencia
    @destinatario_tipo = destinatario_tipo
    @destinatario_esportula = destinatario_esportula
    @destinatario_sacerdote = destinatario_sacerdote
  end

  def eventos_pendentes
    scope = EventoEscala
      .where(competencia_mensal_id: @competencia.id)
      .nao_cancelados
      .where(esportula_modo: "acumulado")
      .where("evento_escala.valor_esportula > 0")
      .where.not(sacerdote_id: nil)
      .where.not(
        id: RegistroEsportula.pagos.where.not(evento_escala_id: nil).select(:evento_escala_id)
      )

    if @destinatario_tipo == "instituicao"
      scope.where(esportula_destinatario_tipo: "instituicao", destinatario_esportula_id: @destinatario_esportula.id)
    else
      scope.where(esportula_destinatario_tipo: "sacerdote", esportula_destinatario_sacerdote_id: @destinatario_sacerdote.id)
    end
  end

  def registrar_pagamento!(data_pagamento:, forma_pagamento: nil)
    eventos = eventos_pendentes.to_a
    raise ArgumentError, "Nenhum evento pendente para este destinatário na competência." if eventos.empty?

    valor = eventos.sum { |e| e.valor_esportula.to_d }

    LotePagamentoEsportula.transaction do
      lote = LotePagamentoEsportula.create!(
        competencia_mensal: @competencia,
        destinatario_tipo: @destinatario_tipo,
        destinatario_esportula: @destinatario_esportula,
        destinatario_sacerdote: @destinatario_sacerdote,
        valor: valor,
        data_pagamento: data_pagamento,
        status: "pago",
        forma_pagamento: forma_pagamento
      )

      eventos.each do |evento|
        lote.lote_pagamento_esportula_eventos.create!(evento_escala: evento)
        sync_registro_pago!(evento, lote)
      end

      Financeiro::EsportulaLancamentoService.sync_from_lote!(lote)
      lote
    end
  end

  private

  def sync_registro_pago!(evento, lote)
    comp = evento.competencia_mensal
    reg = RegistroEsportula.find_or_initialize_by(evento_escala_id: evento.id)
    reg.assign_attributes(
      sacerdote_id: evento.sacerdote_id,
      data: evento.data,
      valor: evento.valor_esportula.to_d,
      competencia_ano: comp.ano,
      competencia_mes: comp.mes,
      status: "pago",
      lote_pagamento_esportula_id: lote.id
    )
    reg.save!
  end
end
