# frozen_string_literal: true

class GeracaoEscalaService
  TIPO_PARA_NOME = {
    "missa" => { nome: "Missa", cor_etiqueta: "#2563eb" },
    "confissao" => { nome: "Confissão", cor_etiqueta: "#7c3aed" }
  }.freeze

  def initialize(competencia_mensal)
    @competencia = competencia_mensal
  end

  def gerar!
    EventoEscala.transaction do
      @competencia.evento_escalas.ordinarios.destroy_all
      criar_eventos
      @competencia.update!(escala_gerada: true)
    end
  end

  def regenerar!
    gerar!
  end

  private

  def criar_eventos
    (1..@competencia.periodo_fim.day).each do |dia|
      data = Date.new(@competencia.ano, @competencia.mes, dia)
      CalendarioBase.ativos.por_dia(data.wday).each do |cb|
        tipo_servico = tipo_servico_para(cb.tipo.to_s)
        next unless tipo_servico

        valor = cb.valor_esportula_override.presence || cb.sacerdote&.valor_esportula_padrao

        @competencia.evento_escalas.create!(
          tipo_servico_id: tipo_servico.id,
          data: data,
          horario: cb.horario,
          quantidade_ministros: cb.quantidade_ministros,
          sacerdote_id: cb.sacerdote_id,
          valor_esportula: valor,
          tipo_escala: "ordinaria",
          status: "pendente"
        )
      end
    end
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
