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
        valor = ev.valor_esportula.to_f
        imediato = ev.esportula_imediato?
        map[ev.sacerdote_id] << {
          horario: ev.horario.strftime("%H:%M"),
          missa: flags[:missa],
          confissao: flags[:confissao],
          previsto: valor,
          previsto_imediato: imediato ? valor : 0,
          realizado: ev.esportula_paga? ? valor : 0
        }
      end
    end

    def esportula_horarios_filtro(eventos)
      eventos.filter_map { |ev| ev.horario&.strftime("%H:%M") }.uniq.sort
    end

    def esportula_nome_curto_destinatario(evento)
      nome = evento.esportula_destinatario_nome.to_s
      nome.sub(/\APe\.\s*/i, "").split(/\s+/).first.presence || nome.truncate(12)
    end

    def esportula_link_lancamento_caixa(lancamento, competencia_mensal_id: nil, label: nil)
      return if lancamento.blank?

      url = if competencia_mensal_id.present?
              admin_lancamentos_caixa_path(
                lancamento,
                return_to: esportulas_competencia_return_path(competencia_mensal_id)
              )
            else
              admin_lancamentos_caixa_path(lancamento)
            end
      titulo = "Lançamento ##{lancamento.id} · #{I18n.l(lancamento.data)} · #{number_to_currency(lancamento.valor_total, precision: 0)}"
      icon_btn = label.blank? ? "shrink-0 p-0.5 rounded text-stone-400 hover:text-sky-700 hover:bg-sky-50 transition-colors" : "inline-flex items-center justify-center gap-0.5 rounded text-sky-700 hover:text-sky-900 hover:bg-sky-50 px-0.5 transition-colors"
      icon_size = label.blank? ? "w-3.5 h-3.5" : "w-3 h-3"
      link_to url,
              class: icon_btn,
              title: titulo,
              aria: { label: "Ver lançamento no financeiro" } do
        safe_join([
          tag.svg(class: "#{icon_size} shrink-0", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24", aria: { hidden: true }) do
            tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
                     d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z")
          end,
          (label.present? ? tag.span(label, class: "text-[9px] font-bold uppercase tracking-wide") : nil)
        ].compact)
      end
    end

  end
end
