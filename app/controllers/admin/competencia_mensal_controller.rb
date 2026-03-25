# frozen_string_literal: true

module Admin
  class CompetenciaMensalController < Admin::BaseController
    # Temporário: liberar geração/regeneração só para este e-mail até regra definitiva.
    EMAIL_AUTORIZADO_GERAR_ESCALA = "ailton@swind.com.br"

    before_action :set_competencia, only: [:show, :edit, :update, :destroy, :gerar_escala, :regenerar_escala]
    before_action :exigir_autorizacao_gerar_escala!, only: %i[gerar_escala regenerar_escala]

    helper_method :pode_gerar_escala_competencia?

    def index
      @competencias = CompetenciaMensal.ordenados

      @competencias = @competencias.where(ano: params[:ano]) if params[:ano].present?
      @competencias = @competencias.where(mes: params[:mes]) if params[:mes].present?
      @competencias = @competencias.where(escala_gerada: params[:escala_gerada]) if params[:escala_gerada].present?

      @competencias = @competencias.page(params[:page])
    end

    def show
      @tem_eventos_na_competencia = @competencia.evento_escalas.exists?

      unless @tem_eventos_na_competencia
        @eventos_contagem = 0
        @eventos_lista = []
        @eventos_calendario_loaded = []
        assign_tabs_and_periodo!
        return
      end

      @eventos = @competencia.evento_escalas.includes(:tipo_servico, :sacerdote, escala_ministros: :ministro)

      @eventos = @eventos.where(tipo_servico_id: params[:tipo_servico_id]) if params[:tipo_servico_id].present?
      @eventos = @eventos.where(sacerdote_id: params[:sacerdote_id]) if params[:sacerdote_id].present?
      if params[:ministro_id].present?
        @eventos = @eventos.where(id: escala_ministro_evento_ids_para_filtro(params[:ministro_id]))
      end
      @eventos = @eventos.where("EXTRACT(DOW FROM data) = ?", params[:dia_semana]) if params[:dia_semana].present?

      assign_tabs_and_periodo!

      @eventos_calendario = @eventos
      @eventos = filtrar_eventos_periodo_lista(@eventos) if @aba == "lista"

      if @aba == "lista"
        @eventos_lista = @eventos.por_data.to_a
        @eventos_contagem = @eventos_lista.size
      else
        @eventos_calendario_loaded = @eventos_calendario.por_data.to_a
        @eventos_contagem = @eventos_calendario_loaded.size
      end
    end

    def new
      @competencia = CompetenciaMensal.new(ano: Date.current.year, mes: Date.current.month)
    end

    def create
      @competencia = CompetenciaMensal.new(competencia_params)
      if @competencia.save
        redirect_to admin_competencia_mensal_path(@competencia), notice: "Competência criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @competencia.update(competencia_params)
        redirect_to admin_competencia_mensal_path(@competencia), notice: "Competência atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @competencia.destroy
      redirect_to admin_competencia_mensal_index_path, notice: "Competência removida com sucesso."
    end

    def gerar_escala
      ::GeracaoEscalaService.new(@competencia).gerar!
      redirect_to admin_competencia_mensal_path(@competencia), notice: "Escala gerada com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_competencia_mensal_path(@competencia), alert: "Erro ao gerar escala: #{e.message}"
    end

    def regenerar_escala
      ::GeracaoEscalaService.new(@competencia).regenerar!
      redirect_to admin_competencia_mensal_path(@competencia), notice: "Escala regenerada com sucesso."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_competencia_mensal_path(@competencia), alert: "Erro ao regenerar escala: #{e.message}"
    end

    private

    def pode_gerar_escala_competencia?
      current_user.present? &&
        current_user.email.to_s.strip.casecmp?(EMAIL_AUTORIZADO_GERAR_ESCALA)
    end

    def exigir_autorizacao_gerar_escala!
      return if pode_gerar_escala_competencia?

      redirect_to admin_competencia_mensal_path(@competencia),
                  alert: "Geração de escala não está disponível para o seu usuário."
    end

    def assign_tabs_and_periodo!
      @vista_lista = params[:vista] == "card" ? "card" : "tabela"
      @aba = params[:aba] == "lista" ? "lista" : "calendario"
      @vista_calendario = %w[semana dia].include?(params[:vista_calendario]) ? params[:vista_calendario] : "mes"
      ref = params[:data_ref].presence&.then { |d| Date.parse(d) rescue nil }
      @data_ref = ref || @competencia.periodo
      @domingo_semana = @data_ref - @data_ref.wday
    end

    def escala_ministro_evento_ids_para_filtro(ministro_id)
      EscalaMinistro.where(ministro_id: ministro_id)
        .where(evento_escala_id: @competencia.evento_escalas.select(:id))
        .distinct
        .pluck(:evento_escala_id)
    end

    def filtrar_eventos_periodo_lista(eventos)
      inicio_cm = @competencia.periodo
      fim_cm = @competencia.periodo_fim

      case @vista_calendario
      when "semana"
        ini = [@domingo_semana, inicio_cm].max
        fim = [@domingo_semana + 6, fim_cm].min
        ini <= fim ? eventos.where(data: ini..fim) : eventos.none
      when "dia"
        (inicio_cm..fim_cm).cover?(@data_ref) ? eventos.where(data: @data_ref) : eventos.none
      else
        eventos
      end
    end

    def set_competencia
      @competencia = CompetenciaMensal.find(params[:id])
    end

    def competencia_params
      params.require(:competencia_mensal).permit(:ano, :mes, :escala_liberada)
    end
  end
end
