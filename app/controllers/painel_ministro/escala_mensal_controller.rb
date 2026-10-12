# frozen_string_literal: true

module PainelMinistro
  # Escala do mês inteira (todos os celebrantes/ministros): versão celular e versão para impressão/PDF.
  class EscalaMensalController < PainelMinistro::BaseController
    # Linha do dia. plantao_rowspan só vem preenchido no primeiro dia exibido do bloco de plantão.
    Dia = Struct.new(:data, :eventos, :extras, :plantao, :plantao_rowspan, :plantao_continuacao, keyword_init: true)

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
      @dias_meus = @dias.select { |d| d.eventos.any? { |e| meu_escala_ministro(e) } }.map(&:data)
    end

    def imprimir
      # A tabela impressa só tem dias com celebrações ordinárias.
      @dias = @dias.select { |d| d.eventos.any? }
      agrupar_plantao!(@dias)
      @total_linhas = @dias.sum { |d| d.eventos.size }
      @fonte_pt = fonte_para_impressao
      render layout: "impressao"
    end

    private

    def meu_escala_ministro(evento)
      evento.escala_ministros.find { |em| em.ministro_id == @meu_id }
    end

    def carregar_escala
      @competencias = CompetenciaMensal.liberadas_para_ministros.ordenados.limit(48).to_a
      @competencia = resolve_competencia
      return redirect_to(ministro_root_path, alert: "Nenhuma escala liberada ainda.") if @competencia.blank?

      eventos = @competencia.evento_escalas
                            .ordinarios.nao_cancelados
                            .includes(:sacerdote, :tipo_servico, escala_ministros: :ministro)
                            .por_data
                            .select(&:requer_ministros?)
      extras = @competencia.evento_escalas
                           .extras.nao_cancelados
                           .includes(:sacerdote, :tipo_servico, escala_ministros: :ministro)
                           .por_data.to_a
      por_dia = eventos.group_by(&:data)
      extras_por_dia = extras.group_by(&:data)
      plantoes = @competencia.plantao_periodos.includes(:ministros).ordenados.to_a

      @dias = (por_dia.keys | extras_por_dia.keys).sort.map do |data|
        Dia.new(data: data, eventos: por_dia[data] || [], extras: extras_por_dia[data] || [],
                plantao: plantoes.find { |p| p.cobre_dia?(data) })
      end
      agrupar_plantao!(@dias)
      @meu_id = current_user.ministro.id
    end

    # Mescla células de "Escala Extra" entre dias consecutivos do mesmo bloco.
    def agrupar_plantao!(dias)
      dias.each_with_index do |dia, i|
        dia.plantao_continuacao = false
        anterior = i.positive? ? dias[i - 1] : nil
        if dia.plantao && anterior&.plantao == dia.plantao
          dia.plantao_continuacao = true
        else
          dia.plantao_rowspan = dia.eventos.size
          j = i + 1
          while dia.plantao && dias[j]&.plantao == dia.plantao
            dia.plantao_rowspan += dias[j].eventos.size
            j += 1
          end
        end
      end
    end

    # Auto: tenta caber o mês numa página A4 retrato. "grande": fonte maior, pode usar 2 páginas.
    def fonte_para_impressao
      return 13.0 if params[:tamanho] == "grande"

      linhas = @total_linhas + @dias.size * 0.15 + 4
      (700.0 / (linhas * 1.75)).clamp(8.0, 13.0).round(1)
    end

    def resolve_competencia
      if params[:competencia_mensal_id].present?
        c = @competencias.find { |x| x.id == params[:competencia_mensal_id].to_i }
        return c if c
      end
      hoje = Date.current
      @competencias.find { |c| c.ano == hoje.year && c.mes == hoje.month } || @competencias.first
    end
  end
end
