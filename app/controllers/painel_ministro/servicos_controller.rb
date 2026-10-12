# frozen_string_literal: true

module PainelMinistro
  class ServicosController < PainelMinistro::BaseController
    def index
      @competencias = CompetenciaMensal.liberadas_para_ministros.ordenados.limit(48).to_a
      @competencia = resolve_competencia(@competencias)
      scope = eventos_do_ministro
      scope = scope.where(competencia_mensal_id: @competencia.id) if @competencia
      @servicos = scope.por_data
    end

    def show
      @servico = eventos_do_ministro.find(params[:id])
      return unless turbo_frame_request_id == "servico_modal"

      @modal = true
      render :modal
    end

    def confirmar
      @servico = eventos_do_ministro.find(params[:id])
      em = @servico.escala_ministros.find_by!(ministro_id: current_user.ministro_id)
      em.confirmar!
      redirect_to voltar_para || ministro_servico_path(@servico), notice: "Presença confirmada."
    end

    private

    # Aceita apenas caminhos internos da área do ministro (evita redirecionamento aberto).
    def voltar_para
      destino = params[:voltar].to_s
      destino if destino.start_with?("/ministro/") && !destino.start_with?("//")
    end

    def resolve_competencia(competencias)
      if params[:competencia_mensal_id].present?
        c = competencias.find { |x| x.id == params[:competencia_mensal_id].to_i }
        return c if c
      end

      competencias.find { |x| x.ano == Date.current.year && x.mes == Date.current.month } || competencias.first
    end

    def eventos_do_ministro
      EventoEscala
        .joins(:competencia_mensal)
        .merge(CompetenciaMensal.liberadas_para_ministros)
        .where(id: EscalaMinistro.where(ministro_id: current_user.ministro_id).select(:evento_escala_id))
        .includes(:tipo_servico, :sacerdote, :plantao_periodo, :competencia_mensal, escala_ministros: :ministro)
        .distinct
        .where.not(status: "cancelado")
    end
  end
end
