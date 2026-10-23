# frozen_string_literal: true

module PlantaoExtraCartazHelper
  # { plantao_periodo.id => [EventoEscala, ...] } para listagens de notificação/cartaz.
  def eventos_extra_por_plantao(plantoes)
    plantoes = Array(plantoes)
    return {} if plantoes.empty?

    resultado = {}
    plantoes.group_by(&:competencia_mensal_id).each_value do |grupo|
      competencia = grupo.first.competencia_mensal
      dias = grupo.flat_map(&:range_dias)
      next if dias.empty?

      min_d, max_d = dias.minmax
      intervalo = Date.new(competencia.ano, competencia.mes, min_d)..Date.new(competencia.ano, competencia.mes, max_d)
      eventos = competencia.evento_escalas.extras.nao_cancelados
                           .where(data: intervalo)
                           .includes(:tipo_servico)
                           .por_data
                           .to_a

      grupo.each do |pp|
        datas = pp.range_dias.filter_map do |dia|
          Date.new(competencia.ano, competencia.mes, dia)
        rescue ArgumentError
          nil
        end
        resultado[pp.id] = eventos.select { |e| datas.include?(e.data) }
      end
    rescue ArgumentError
      next
    end
    resultado
  end

  def plantao_extra_cartaz_path(plantao)
    if escala_extra_context?
      escala_extra_plantao_cartaz_path(plantao)
    else
      cartaz_admin_competencia_mensal_plantao_periodo_path(plantao.competencia_mensal, plantao)
    end
  end

  def evento_cartaz_titulo(evento)
    parts = []
    parts << evento.tipo_servico.nome if evento.tipo_servico.present?
    parts << evento.descricao if evento.descricao.present?
    texto = parts.join(" — ")
    texto.presence || evento.tipo_servico&.nome.to_s
  end

  def evento_cartaz_icone(evento)
    nome = [evento.tipo_servico&.nome, evento.descricao].compact.join(" ").downcase
    if nome.include?("adora")
      :adoracao
    elsif nome.include?("comunic")
      :comunicacao
    else
      :missa
    end
  end

  def cartaz_icone_svg(kind)
    inner = case kind
            when :missa
              tag.path(d: "M7 11h10v10H7z") + tag.path(d: "M12 4v4M9 8h6")
            when :adoracao
              tag.circle(cx: 12, cy: 12, r: 4) + tag.path(d: "M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41")
            when :comunicacao
              tag.rect(x: 4, y: 6, width: 16, height: 12, rx: 2) + tag.path(d: "M8 18v3l4-3")
            when :local
              tag.path(d: "M12 21s7-4.5 7-11a7 7 0 10-14 0c0 6.5 7 11 7 11z") + tag.circle(cx: 12, cy: 10, r: 2)
            else
              ""
            end
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: 2, aria: { hidden: true }) do
      inner
    end
  end
end
