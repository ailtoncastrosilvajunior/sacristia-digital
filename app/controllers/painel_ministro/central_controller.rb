# frozen_string_literal: true

module PainelMinistro
  # Tela única do ministro: próximo serviço, calendário do mês, próximas celebrações e atalhos.
  # O tema (cores) segue a cor litúrgica do dia.
  class CentralController < PainelMinistro::BaseController
    def index
      @ministro = current_user.ministro
      @hoje = Date.current

      carregar_proximo_servico
      carregar_escala_do_mes

      @liturgia_hoje = LiturgiaDia.validadas.with_attached_imagem_santo.find_by(data: @hoje)
      @liturgia_proximo = @proximo && LiturgiaDia.validadas.find_by(data: @proximo.data)
      @tema = helpers.tema_liturgico(@liturgia_hoje || @liturgia_proximo)
      @trocas_pendentes = SolicitacaoTroca.pendentes.where(substituto_id: @ministro.id).count
      carregar_trocas
    end

    private

    # Pedidos de troca já feitos pelo ministro (por escala_ministro) e candidatos a substituto, para as ações nos cards.
    def carregar_trocas
      em_ids = (@eventos.to_a + [@proximo].compact).flat_map { |e| e.escala_ministros.select { |em| em.ministro_id == @ministro.id }.map(&:id) }
      @trocas_pedidas = SolicitacaoTroca.pendentes.where(escala_ministro_id: em_ids).includes(:substituto).index_by(&:escala_ministro_id)
      @ministros_para_troca = Ministro.ativos.ordenados_por_nome.where.not(id: @ministro.id).to_a
    end

    # Próximo serviço do ministro em qualquer competência liberada.
    def carregar_proximo_servico
      eventos = EventoEscala
        .joins(:escala_ministros, :competencia_mensal)
        .where(escala_ministros: { ministro_id: @ministro.id }, competencia_mensal: { escala_liberada: true })
        .where(data: @hoje..)
        .includes(:tipo_servico, :sacerdote, escala_ministros: :ministro)
        .distinct
        .order(:data, :horario)
        .limit(40)
        .reject(&:cancelado?)

      limite = (Time.current - 1.hour).strftime("%H%M")
      @proximo = eventos.find { |e| e.data > @hoje || e.horario.strftime("%H%M") >= limite }
      @meu_papel = @proximo&.escala_ministros&.find { |em| em.ministro_id == @ministro.id }
    end

    # Agenda (dias de serviço e plantão) da competência escolhida (padrão: mês atual).
    def carregar_escala_do_mes
      @competencias = CompetenciaMensal.liberadas_para_ministros.ordenados.limit(48)
      @competencia = resolve_competencia(@competencias)
      return if @competencia.blank?

      @eventos = EventoEscala
        .joins(:escala_ministros)
        .where(competencia_mensal_id: @competencia.id, escala_ministros: { ministro_id: @ministro.id })
        .includes(:tipo_servico, :sacerdote, escala_ministros: :ministro)
        .distinct
        .order(:data, :horario)
        .reject(&:cancelado?)

      @plantao_por_dia = build_plantao_por_dia(@competencia, @ministro)
      por_dia = @eventos.group_by(&:data)
      @dias_agenda = (por_dia.keys | @plantao_por_dia.keys).sort.map do |data|
        { data: data, eventos: (por_dia[data] || []).sort_by(&:horario), plantao: @plantao_por_dia[data] }
      end
    end

    def resolve_competencia(competencias)
      if params[:competencia_mensal_id].present?
        c = competencias.find_by(id: params[:competencia_mensal_id])
        return c if c
      end

      cur = CompetenciaMensal.find_by(ano: @hoje.year, mes: @hoje.month)
      return cur if cur && competencias.exists?(id: cur.id)

      competencias.first
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
  end
end
