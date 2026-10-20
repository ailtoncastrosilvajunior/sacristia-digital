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
      @dias_meus = @dias.select { |d| d.eventos.any? { |e| meu_escala_ministro(e) } }.map(&:data)
    end

    private

    def meu_escala_ministro(evento)
      evento.escala_ministros.find { |em| em.ministro_id == @meu_id }
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
