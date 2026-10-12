# frozen_string_literal: true

module PainelMinistro
  class DashboardController < PainelMinistro::BaseController
    def index
      @ministro_record = current_user.ministro
      return if @ministro_record.blank?

      @competencias = competencias_do_ministro(@ministro_record)
      @competencia = resolve_competencia(@competencias)
      return if @competencia.blank?

      base = EventoEscala
        .joins(:escala_ministros)
        .where(competencia_mensal_id: @competencia.id, escala_ministros: { ministro_id: @ministro_record.id })
        .includes(:tipo_servico, :sacerdote, escala_ministros: :ministro)
        .distinct
        .order(:data, :horario)

      @eventos = base.reject(&:cancelado?)
      @stats = build_stats(@eventos, @ministro_record.id)
      hoje = Date.current
      @lista_desde = parse_lista_desde(@competencia)
      inicio_lista = @lista_desde || hoje
      @proximos = @eventos.select { |e| e.data >= inicio_lista }.first(12)
      @recentes_passados = @eventos.select { |e| e.data < hoje }.last(5).reverse
      @plantao_por_dia = build_plantao_por_dia(@competencia, @ministro_record)
      @heatmap = build_heatmap_ministro(@competencia, @eventos, @plantao_por_dia)
      @eventos_dia_filtro = @lista_desde ? @eventos.select { |e| e.data == @lista_desde }.sort_by(&:horario) : []
    end

    private

    def competencias_do_ministro(_ministro)
      CompetenciaMensal
        .liberadas_para_ministros
        .ordenados
        .limit(48)
    end

    def resolve_competencia(competencias)
      if params[:competencia_mensal_id].present?
        c = competencias.find_by(id: params[:competencia_mensal_id])
        return c if c
      end

      cur = CompetenciaMensal.find_by(ano: Date.current.year, mes: Date.current.month)
      return cur if cur && competencias.exists?(id: cur.id)

      competencias.first
    end

    def parse_lista_desde(competencia)
      raw = params[:lista_desde].presence
      return nil unless raw

      d = Date.strptime(raw.to_s, "%Y-%m-%d")
      return nil unless d.between?(competencia.periodo, competencia.periodo_fim)

      d
    rescue ArgumentError
      nil
    end

    def build_stats(eventos, ministro_id)
      total = eventos.size
      if total.zero?
        return {
          total: 0,
          como_coord: 0,
          como_ador: 0,
          confirmados: 0,
          pendentes_confirmacao: 0,
          dias_com_servico: 0
        }
      end

      como_coord = eventos.count { |e| papel_no_evento(e, ministro_id)&.coordenador? }
      como_ador = eventos.count { |e| papel_no_evento(e, ministro_id)&.adoracao? }
      confirmados = eventos.count { |e| papel_no_evento(e, ministro_id)&.confirmado? }
      dias = eventos.map(&:data).uniq.size

      {
        total: total,
        como_coord: como_coord,
        como_ador: como_ador,
        confirmados: confirmados,
        pendentes_confirmacao: total - confirmados,
        dias_com_servico: dias
      }
    end

    def papel_no_evento(evento, ministro_id)
      evento.escala_ministros.find { |em| em.ministro_id == ministro_id }
    end

    # { Date => PlantaoPeriodo } dos dias em que o ministro está de plantão (escala extra).
    def build_plantao_por_dia(competencia, ministro)
      blocos = PlantaoPeriodo
        .joins(:plantao_periodo_ministros)
        .where(competencia_mensal_id: competencia.id, plantao_periodo_ministros: { ministro_id: ministro.id })
        .includes(plantao_periodo_ministros: :ministro)
        .ordenados

      ultimo = competencia.periodo_fim.day
      blocos.each_with_object({}) do |bloco, mapa|
        bloco.range_dias.each do |dia|
          next if dia > ultimo
          mapa[Date.new(competencia.ano, competencia.mes, dia)] = bloco
        end
      end
    end

    def build_heatmap_ministro(competencia, eventos, plantao_por_dia)
      por_dia = eventos.group_by(&:data)
      (competencia.periodo..competencia.periodo_fim).map do |d|
        dia_eventos = por_dia[d] || []
        {
          data: d,
          count: dia_eventos.size,
          ordinaria: dia_eventos.count(&:ordinario?),
          extra: dia_eventos.count(&:extra?),
          plantao: plantao_por_dia.key?(d)
        }
      end
    end
  end
end
