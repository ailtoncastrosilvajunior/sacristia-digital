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

  def escala_plantao_texto(plantao)
    plantao.ministros.map(&:nome).join(" | ")
  end

  def escala_celebrante(evento)
    evento.sacerdote&.nome.presence || evento.tipo_servico&.nome.presence || "—"
  end

  def escala_dia_semana(data)
    I18n.l(data, format: "%A")
  end
end
