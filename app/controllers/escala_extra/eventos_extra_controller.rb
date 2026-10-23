# frozen_string_literal: true

module EscalaExtra
  class EventosExtraController < EscalaExtra::BaseController
    include EventosExtraCrud

    # Reaproveita as views do CRUD de admin/eventos_extra.
    def _prefixes
      @_prefixes ||= super + ["admin/eventos_extra"]
    end

    # Detalhes do evento no drawer lateral (turbo-frame evento_drawer).
    def drawer
      @evento = EventoEscala.extras.includes(:tipo_servico, :sacerdote, { plantao_periodo: :ministros }, :competencia_mensal, escala_ministros: :ministro).find(params[:id])
      render partial: "admin/evento_escala/show_drawer", layout: false
    end

    private

    # Agendadores não veem nem alteram a espórtula.
    def campos_permitidos
      super - [:valor_esportula]
    end
  end
end
