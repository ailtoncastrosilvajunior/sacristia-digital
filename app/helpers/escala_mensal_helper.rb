# frozen_string_literal: true

module EscalaMensalHelper
  # [{ nome:, adoracao:, coordenador:, meu: }] com coordenador primeiro, depois ordem alfabética.
  def escala_ministros_do_evento(evento, meu_id = nil)
    evento.escala_ministros.select { |em| em.ministro.present? }
          .sort_by { |em| [em.coordenador? ? 0 : 1, I18n.transliterate(em.ministro.nome.to_s).downcase] }
          .map do |em|
      { nome: em.ministro.nome, adoracao: em.adoracao?, coordenador: em.coordenador?, meu: em.ministro_id == meu_id,
        confirmado: em.confirmado?, em_id: em.id, ministro_id: em.ministro_id }
    end
  end

  def escala_nomes_texto(evento)
    escala_ministros_do_evento(evento).map { |m| m[:adoracao] ? "#{m[:nome]}(Adoração)" : m[:nome] }.join(" | ")
  end

  # "Dias 1 a 2" / "Dia 5": período do plantão repetido na coluna Escala Extra do relatório.
  def escala_plantao_dias_texto(plantao)
    return "Dia #{plantao.dia_inicio}" if plantao.dia_inicio == plantao.dia_fim

    "Dias #{plantao.dia_inicio} a #{plantao.dia_fim}"
  end

  def escala_plantao_texto(plantao)
    plantao.ministros.map(&:nome).join(" | ")
  end

  # Paths do relatório impresso conforme a área (admin ou painel do ministro): o mesmo relatório serve aos dois.
  def escala_imprimir_path(params = {})
    if controller_path.start_with?("admin")
      admin_escala_mensal_imprimir_path(params)
    else
      ministro_escala_mensal_imprimir_path(params)
    end
  end

  def escala_imprimir_voltar_path(competencia)
    if controller_path.start_with?("admin")
      admin_competencia_mensal_path(competencia)
    else
      ministro_escala_mensal_path(competencia_mensal_id: competencia.id)
    end
  end

  def escala_celebrante(evento)
    evento.sacerdote&.nome.presence || evento.tipo_servico&.nome.presence || "—"
  end

  def escala_dia_semana(data)
    I18n.l(data, format: "%A")
  end
end
