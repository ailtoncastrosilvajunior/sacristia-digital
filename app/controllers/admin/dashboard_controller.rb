# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def index
      @competencias = CompetenciaMensal.ordenados.limit(48)
      @competencia = resolve_competencia
      return if @competencia.blank?

      base = @competencia.evento_escalas
        .includes(:tipo_servico, :sacerdote, escala_ministros: :ministro)
      @eventos_todos = base.order(:data, :horario).to_a
      @eventos = @eventos_todos.reject(&:cancelado?)
      @stats = build_stats(@eventos)
      @eventos_por_dia = @eventos.group_by(&:data)
      hoje = Date.current
      @lista_desde = parse_lista_desde(@competencia)
      inicio_lista = @lista_desde || hoje
      @proximos = @eventos.select { |e| e.data >= inicio_lista }.first(12)
      @recentes_passados = @eventos.select { |e| e.data < hoje }.last(5).reverse
      @heatmap = build_heatmap(@competencia, @eventos)
      @picos_mes = @eventos.group_by(&:data).transform_values(&:size).sort_by { |_d, n| -n }.first(3)
      @eventos_dia_filtro = @lista_desde ? @eventos.select { |e| e.data == @lista_desde }.sort_by(&:horario) : []
      load_esportulas_resumo(@competencia)
    end

    private

    def parse_lista_desde(competencia)
      raw = params[:lista_desde].presence
      return nil unless raw

      d = Date.strptime(raw.to_s, "%Y-%m-%d")
      return nil unless d.between?(competencia.periodo, competencia.periodo_fim)

      d
    rescue ArgumentError
      nil
    end

    def resolve_competencia
      if params[:competencia_mensal_id].present?
        return CompetenciaMensal.find_by(id: params[:competencia_mensal_id])
      end

      CompetenciaMensal.find_by(ano: Date.current.year, mes: Date.current.month) ||
        CompetenciaMensal.ordenados.first
    end

    def build_stats(eventos)
      total = eventos.size
      return { total: 0 } if total.zero?

      com_ministros = eventos.count { |e| e.escala_ministros.any? }
      com_sacerdote = eventos.count { |e| e.sacerdote_id.present? }
      com_coord = eventos.count { |e| e.escala_ministros.any?(&:coordenador?) }
      com_adoracao = eventos.count { |e| e.escala_ministros.any?(&:adoracao?) }
      pendentes = eventos.count { |e| e.status == "pendente" }
      confirmados = eventos.count { |e| e.status == "confirmado" }
      concluidos = eventos.count { |e| e.status == "concluido" }
      dias_com_servico = eventos.map(&:data).uniq.size

      {
        total: total,
        com_ministros: com_ministros,
        com_sacerdote: com_sacerdote,
        com_coord: com_coord,
        com_adoracao: com_adoracao,
        pendentes: pendentes,
        confirmados: confirmados,
        concluidos: concluidos,
        dias_com_servico: dias_com_servico,
        pct_equipe: total.positive? ? ((com_ministros.to_f / total) * 100).round : 0
      }
    end

    def load_esportulas_resumo(competencia)
      registros = RegistroEsportula
        .includes(:sacerdote)
        .por_competencia(competencia.ano, competencia.mes)
        .order(data: :desc, created_at: :desc)
        .to_a

      pendentes = registros.select { |r| r.status == "pendente" }
      pagos = registros.select { |r| r.status == "pago" }

      @esportulas_stats = {
        total: registros.size,
        pendentes: pendentes.size,
        pagos: pagos.size,
        valor_pendente: pendentes.sum(&:valor),
        valor_pago: pagos.sum(&:valor)
      }
      @esportulas_recentes = registros.first(8)
    end

    def build_heatmap(competencia, eventos)
      inicio = competencia.periodo
      fim = competencia.periodo_fim
      counts = eventos.group_by(&:data).transform_values(&:size)
      (inicio..fim).map do |d|
        { data: d, count: counts[d] || 0 }
      end
    end
  end
end
