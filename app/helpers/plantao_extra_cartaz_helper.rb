# frozen_string_literal: true

module PlantaoExtraCartazHelper
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

  def evento_cartaz_responsavel(evento)
    coord = evento.ministro_coordenador
    return { nome: coord.nome, telefone: coord.telefone } if coord.present?

    evento.ministros.find { |m| m.telefone.present? }&.then { |m| { nome: m.nome, telefone: m.telefone } }
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
            when :pessoa
              tag.circle(cx: 12, cy: 8, r: 3) + tag.path(d: "M6 20c0-3 2.5-5 6-5s6 2 6 5")
            else
              ""
            end
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: 2, aria: { hidden: true }) do
      inner
    end
  end
end
