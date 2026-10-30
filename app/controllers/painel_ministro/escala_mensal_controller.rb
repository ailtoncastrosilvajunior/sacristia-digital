# frozen_string_literal: true

module PainelMinistro
  # Escala do mês inteira (todos os celebrantes/ministros): versão celular e versão para impressão/PDF.
  class EscalaMensalController < PainelMinistro::BaseController
    include EscalaMensalImpressao

    before_action :carregar_escala

    helper_method :meu_escala_ministro

    def show
      @hoje = Date.current
      em_ids = @dias.flat_map { |d| d.eventos.flat_map { |e| e.escala_ministros.map(&:id) } }
      @trocas_pendentes = SolicitacaoTroca.pendentes.where(escala_ministro_id: em_ids).index_by(&:escala_ministro_id)
      ofertas = OfertaApoio.ativas.where(competencia_mensal_id: @competencia.id).includes(:ministro).to_a
      @apoiadores_por_dia = ofertas.group_by(&:data)
      @apoios = ofertas.select { |o| o.ministro_id == @meu_id }.index_by(&:data)
      @ministros_para_troca = Ministro.ativos.ordenados_por_nome.where.not(id: @meu_id).to_a
      @trocas_recebidas = SolicitacaoTroca.pendentes.where(substituto_id: @meu_id)
                                          .includes(escala_ministro: [:ministro, { evento_escala: %i[tipo_servico sacerdote] }])
                                          .select { |t| !t.evento_escala.cancelado? && t.evento_escala.data >= @hoje }
                                          .sort_by { |t| [t.evento_escala.data, t.evento_escala.horario] }
      enriquecer_dias_plantao_ministro!
      @dias_meus_celebracao = @dias.select { |d| d.eventos.any? { |e| meu_escala_ministro(e) } }.map(&:data)
      @dias_meus_plantao = datas_plantao_do_ministro(@competencia, @meu_id)
      @dias_meus = (@dias_meus_celebracao | @dias_meus_plantao).sort
    end

    private

    def meu_escala_ministro(evento)
      evento.escala_ministros.find { |em| em.ministro_id == @meu_id }
    end

    # Dias só de plantão (sem missa na lista) entram para o ministro ver no calendário e na lista.
    def enriquecer_dias_plantao_ministro!
      datas = datas_plantao_do_ministro(@competencia, @meu_id)
      return if datas.empty?

      plantoes = @competencia.plantao_periodos.includes(:ministros).ordenados.to_a
      por_data = @dias.index_by(&:data)
      datas.each do |data|
        next if por_data[data]

        plantao = plantoes.find { |p| p.cobre_dia?(data) }
        next unless plantao

        @dias << EscalaMensalImpressao::Dia.new(data: data, eventos: [], extras: [], plantao: plantao)
      end
      @dias.sort_by!(&:data)
      agrupar_plantao!(@dias)
    end

    def datas_plantao_do_ministro(competencia, ministro_id)
      blocos = PlantaoPeriodo
        .joins(:plantao_periodo_ministros)
        .where(competencia_mensal_id: competencia.id, plantao_periodo_ministros: { ministro_id: ministro_id })
        .ordenados
      ultimo = competencia.periodo_fim.day
      blocos.flat_map do |bloco|
        bloco.range_dias.filter_map do |dia|
          next if dia > ultimo

          Date.new(competencia.ano, competencia.mes, dia)
        end
      end.uniq.sort
    end

    def carregar_escala
      @competencias = CompetenciaMensal.liberadas_para_ministros.ordenados.limit(48).to_a
      @competencia = resolve_competencia
      return redirect_to(ministro_root_path, alert: "Nenhuma escala liberada ainda.") if @competencia.blank?

      montar_escala_mensal
      @meu_id = current_user.ministro.id
    end
  end
end
