# frozen_string_literal: true

module Admin
  module CompetenciaMensalHelper
    ICON_COORDENADOR = <<~SVG.freeze
      <svg class="w-3 h-3 shrink-0" fill="currentColor" viewBox="0 0 20 20" title="Coordenador"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
    SVG

    def render_ministros_com_coordenador(evento)
      return "—".html_safe if evento.ministros.empty?

      coord = evento.ministro_coordenador
      partes = evento.ministros.map do |m|
        if coord && m.id == coord.id
          content_tag(:span, class: "inline-flex items-center gap-0.5 text-sky-600 font-medium", title: "Coordenador") do
            safe_join([ICON_COORDENADOR.html_safe, m.nome], " ")
          end
        else
          m.nome
        end
      end
      safe_join(partes, ", ")
    end
  end
end
