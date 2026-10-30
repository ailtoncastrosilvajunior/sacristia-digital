# frozen_string_literal: true

class GeracaoEscalaService
  TIPO_PARA_NOME = {
    "missa" => { nome: "Missa", cor_etiqueta: "#2563eb" },
    "confissao" => { nome: "Confissão", cor_etiqueta: "#7c3aed" }
  }.freeze

  def initialize(competencia_mensal)
    @competencia = competencia_mensal
  end

  MODOS = %w[substituir manter].freeze

  # modo "substituir": apaga os eventos ordinários atuais e gera tudo de novo.
  # modo "manter": preserva todos os eventos existentes e cria apenas os que ainda não existem
  # (mesma data, horário e tipo de serviço). Retorna a quantidade de eventos criados.
  def gerar!(modo: "substituir")
    modo = MODOS.include?(modo.to_s) ? modo.to_s : "substituir"
    criados = 0
    EventoEscala.transaction do
      @competencia.evento_escalas.ordinarios.destroy_all if modo == "substituir"
      criados = criar_eventos(manter_existentes: modo == "manter")
      @competencia.update!(escala_gerada: true)
    end
    criados
  end

  def regenerar!
    gerar!
  end

  private

  def criar_eventos(manter_existentes: false)
    criados = 0
    existentes = manter_existentes ? @competencia.evento_escalas.pluck(:data, :horario, :tipo_servico_id).map { |d, h, t| [d, h.strftime("%H:%M"), t] }.to_set : Set.new
    (1..@competencia.periodo_fim.day).each do |dia|
      data = Date.new(@competencia.ano, @competencia.mes, dia)
      CalendarioBase.ativos.por_dia(data.wday).each do |cb|
        tipo_servico = tipo_servico_para(cb.tipo.to_s)
        next unless tipo_servico

        valor = cb.valor_esportula_override.presence || cb.sacerdote&.valor_esportula_padrao

        next if existentes.include?([data, cb.horario.strftime("%H:%M"), tipo_servico.id])

        criados += 1
        evento = @competencia.evento_escalas.create!(
          tipo_servico_id: tipo_servico.id,
          data: data,
          horario: cb.horario,
          quantidade_ministros: cb.quantidade_ministros,
          sacerdote_id: cb.sacerdote_id,
          valor_esportula: valor,
          tipo_escala: "ordinaria",
          status: "confirmado",
          calendario_base_id: cb.id
        )
        EsportulaDestinatarioResolver.apply!(evento, calendario_base: cb)
      end
    end
    criados
  end

  def tipo_servico_para(tipo)
    tipo_str = tipo.to_s.downcase.strip
    attrs = TIPO_PARA_NOME[tipo_str]
    return nil unless attrs

    ts = TipoServico.find_or_initialize_by(nome: attrs[:nome])
    ts.assign_attributes(tipo_escala: "ordinaria", cor_etiqueta: attrs[:cor_etiqueta], ativo: true)
    ts.save!
    ts
  end
end
