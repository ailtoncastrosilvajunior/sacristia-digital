# frozen_string_literal: true

# Define modo (imediato/acumulado) e destinatário do pagamento por evento.
# Prioridade: por_periodo do sacerdote > slot acumulado instituição (titular) > imediato ao celebrante.
class EsportulaDestinatarioResolver
  def self.apply!(evento, calendario_base: nil, force: false)
    new(evento, calendario_base: calendario_base).apply!(force: force)
  end

  def initialize(evento, calendario_base: nil)
    @evento = evento
    @calendario_base = calendario_base || evento.calendario_base || self.class.infer_calendario_para(evento)
  end

  def self.infer_calendario_para(evento)
    return nil unless evento.data && evento.horario

    hora = evento.horario.strftime("%H:%M:%S")
    CalendarioBase.ativos.por_dia(evento.data.wday).find { |cb| cb.horario.strftime("%H:%M:%S") == hora }
  end

  def apply!(force: false)
    return @evento if @evento.esportula_destinatario_manual? && !force
    return @evento if @evento.sacerdote_id.blank?
    return @evento if evento_ja_quitado?

    attrs = compute_attributes
    @evento.assign_attributes(attrs)
    @evento.save! if @evento.persisted? && @evento.changed?
    @evento
  end

  def compute_attributes
    sacerdote = @evento.sacerdote
    cb = @calendario_base

    if sacerdote&.por_periodo?
      return acumulado_sacerdote(sacerdote)
    end

    if cb&.esportula_acumulado? && cb.destinatario_esportula_id.present? && titular_no_slot?(cb)
      return acumulado_instituicao(cb.destinatario_esportula_id)
    end

    imediato_celebrante(sacerdote)
  end

  private

  def evento_ja_quitado?
    @evento.esportula_paga? || @evento.lote_pagamento_esportula_evento&.lote_pagamento_esportula&.pago?
  end

  def titular_no_slot?(cb)
    @evento.sacerdote_id == cb.sacerdote_id
  end

  def acumulado_sacerdote(sacerdote)
    {
      esportula_modo: "acumulado",
      esportula_destinatario_tipo: "sacerdote",
      esportula_destinatario_sacerdote_id: sacerdote.id,
      destinatario_esportula_id: nil
    }
  end

  def acumulado_instituicao(instituicao_id)
    {
      esportula_modo: "acumulado",
      esportula_destinatario_tipo: "instituicao",
      destinatario_esportula_id: instituicao_id,
      esportula_destinatario_sacerdote_id: nil
    }
  end

  def imediato_celebrante(sacerdote)
    {
      esportula_modo: "imediato",
      esportula_destinatario_tipo: "sacerdote",
      esportula_destinatario_sacerdote_id: sacerdote.id,
      destinatario_esportula_id: nil
    }
  end
end
