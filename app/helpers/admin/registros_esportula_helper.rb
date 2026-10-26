# frozen_string_literal: true

module Admin
  module RegistrosEsportulaHelper
    def esportula_pct_global(totais)
      return 0 if totais.blank? || totais[:previsto].to_d.zero?

      ((totais[:realizado].to_d / totais[:previsto].to_d) * 100).round
    end

    def esportula_turno_class(horario)
      hora = horario.hour
      if hora < 11
        "bg-amber-100 text-amber-900 ring-amber-200/80"
      elsif hora < 15
        "bg-sky-100 text-sky-900 ring-sky-200/80"
      elsif hora >= 17
        "bg-emerald-100 text-emerald-900 ring-emerald-200/80"
      else
        "bg-stone-100 text-stone-700 ring-stone-200/80"
      end
    end

    def esportula_nome_curto(sacerdote)
      sacerdote.nome.sub(/\APe\.\s*/i, "").split(/\s+/).first
    end

    def esportulas_competencia_return_path(competencia_mensal_id)
      competencia_admin_registros_esportula_index_path(competencia_mensal_id: competencia_mensal_id)
    end

    def edit_evento_from_esportulas_path(evento)
      edit_admin_evento_escala_path(
        evento,
        return_to: esportulas_competencia_return_path(evento.competencia_mensal_id)
      )
    end

    def esportula_tipo_flags(tipo_nome)
      nome = tipo_nome.to_s
      { missa: nome.match?(/missa/i), confissao: nome.match?(/confiss/i) }
    end

    def esportula_resumo_eventos_map(eventos)
      eventos.each_with_object({}) do |ev, map|
        next if ev.sacerdote_id.blank?

        flags = esportula_tipo_flags(ev.tipo_servico.nome)
        map[ev.sacerdote_id] ||= []
        map[ev.sacerdote_id] << {
          horario: ev.horario.strftime("%H:%M"),
          missa: flags[:missa],
          confissao: flags[:confissao],
          previsto: ev.valor_esportula.to_f,
          realizado: ev.esportula_paga? ? ev.valor_esportula.to_f : 0
        }
      end
    end

    def esportula_horarios_filtro(eventos)
      eventos.filter_map { |ev| ev.horario&.strftime("%H:%M") }.uniq.sort
    end

  end
end
