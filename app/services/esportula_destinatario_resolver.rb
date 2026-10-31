# frozen_string_literal: true

# Define modo (imediato/acumulado) e destinatário do pagamento por evento.
# Prioridade: substituto no slot > calendário base (modo/instituição) > por_periodo do sacerdote > imediato ao celebrante.
class EsportulaDestinatarioResolver
  TIPO_SERVICO_PARA_CALENDARIO = {
    "missa" => "missa",
    "confissão" => "confissao",
    "confissao" => "confissao"
  }.freeze
  def self.apply!(evento, calendario_base: nil, force: false)
    new(evento, calendario_base: calendario_base).apply!(force: force)
  end

  def initialize(evento, calendario_base: nil)
    @evento = evento
    @calendario_base = calendario_base || evento.calendario_base || self.class.infer_calendario_para(evento)
  end

  def self.infer_calendario_para(evento)
    return evento.calendario_base if evento.calendario_base.present?
    return nil unless evento.data && evento.horario

    hora = evento.horario.strftime("%H:%M:%S")
    candidatos = CalendarioBase.ativos.por_dia(evento.data.wday).select { |cb| cb.horario.strftime("%H:%M:%S") == hora }
    return candidatos.first if candidatos.size <= 1

    tipo_cal = tipo_calendario_para_evento(evento)
    candidatos.find { |cb| cb.tipo == tipo_cal } || candidatos.first
  end

  def self.tipo_calendario_para_evento(evento)
    nome = evento.tipo_servico&.nome.to_s.downcase.strip
    TIPO_SERVICO_PARA_CALENDARIO[nome] || "missa"
  end

  def apply!(force: false)
    return @evento if @evento.esportula_destinatario_manual? && !force
    return @evento if @evento.sacerdote_id.blank? && !esportula_definida_no_calendario?
    return @evento if evento_ja_quitado?

    attrs = compute_attributes
    @evento.assign_attributes(attrs)
    @evento.save! if @evento.persisted? && @evento.changed?
    @evento
  end

  def compute_attributes
    sacerdote = @evento.sacerdote
    cb = @calendario_base

    if substituto_no_slot?(cb)
      return imediato_celebrante(sacerdote)
    end

    if cb&.esportula_acumulado? && cb.destinatario_esportula_id.present? && titular_ou_sem_sacerdote_no_slot?(cb)
      return acumulado_instituicao(cb.destinatario_esportula_id)
    end

    if cb.present? && !cb.esportula_acumulado?
      return imediato_celebrante(sacerdote)
    end

    if sacerdote&.por_periodo?
      return acumulado_sacerdote(sacerdote)
    end

    imediato_celebrante(sacerdote)
  end

  private

  def esportula_definida_no_calendario?
    cb = @calendario_base
    cb&.esportula_acumulado? && cb.destinatario_esportula_id.present?
  end

  def substituto_no_slot?(cb)
    return false if cb.blank? || cb.sacerdote_id.blank? || @evento.sacerdote_id.blank?

    @evento.sacerdote_id != cb.sacerdote_id
  end

  def titular_ou_sem_sacerdote_no_slot?(cb)
    @evento.sacerdote_id.blank? || titular_no_slot?(cb)
  end

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
      esportula_destinatario_sacerdote_id: sacerdote&.id,
      destinatario_esportula_id: nil
    }
  end
end
