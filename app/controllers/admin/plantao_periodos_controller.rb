# frozen_string_literal: true

module Admin
  # Plantão extra por competência: blocos de dias + ministros.
  class PlantaoPeriodosController < Admin::BaseController
    include PlantaoExtraCartazRender

    before_action :set_competencia
    before_action :set_plantao, only: %i[edit update destroy cartaz]

    def index
      @aba = params[:aba] == "notificacao" ? "notificacao" : "calendario"
      @plantao_periodos = @competencia.plantao_periodos.includes(:ministros).ordenados
      @dias_sem_plantao = dias_sem_plantao(@plantao_periodos)
      @competencia_anterior = @competencia.competencia_anterior
    end

    def new
      inicio = params[:dia_inicio].presence&.to_i || proximo_dia_livre
      inicio = inicio.clamp(1, @competencia.periodo_fim.day)
      @plantao = @competencia.plantao_periodos.new(dia_inicio: inicio, dia_fim: [inicio + 1, @competencia.periodo_fim.day].min)
    end

    def create
      @plantao = @competencia.plantao_periodos.new(plantao_params)
      if @plantao.save
        redirect_to admin_competencia_mensal_plantao_periodos_path(@competencia), notice: "Bloco de plantão criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @plantao.update(plantao_params)
        redirect_to admin_competencia_mensal_plantao_periodos_path(@competencia), notice: "Bloco de plantão atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @plantao.destroy
      redirect_to admin_competencia_mensal_plantao_periodos_path(@competencia), notice: "Bloco de plantão removido."
    end

    def cartaz
      render_plantao_extra_cartaz
    end

    # Copia dias e ministros da competência anterior.
    def copiar_anterior
      origem = @competencia.competencia_anterior
      if origem.nil? || origem.plantao_periodos.none?
        redirect_to admin_competencia_mensal_plantao_periodos_path(@competencia), alert: "Não há plantão na competência anterior para copiar."
      elsif @competencia.plantao_periodos.exists?
        redirect_to admin_competencia_mensal_plantao_periodos_path(@competencia), alert: "Esta competência já possui blocos de plantão. Remova-os antes de copiar."
      else
        @competencia.copiar_plantao_de!(origem)
        redirect_to admin_competencia_mensal_plantao_periodos_path(@competencia), notice: "Plantão copiado de #{origem.label}."
      end
    end

    private

    def set_competencia
      @competencia = CompetenciaMensal.find(params[:competencia_mensal_id])
    end

    def set_plantao
      @plantao = @competencia.plantao_periodos.find(params[:id])
    end

    def plantao_params
      permitido = params.require(:plantao_periodo).permit(:dia_inicio, :dia_fim, ministro_ids: [])
      permitido[:ministro_ids] = Array(permitido[:ministro_ids]).compact_blank
      permitido
    end

    def dias_sem_plantao(periodos)
      cobertos = periodos.flat_map(&:range_dias)
      (1..@competencia.periodo_fim.day).to_a - cobertos
    end

    def proximo_dia_livre
      cobertos = @competencia.plantao_periodos.flat_map(&:range_dias)
      (1..@competencia.periodo_fim.day).find { |d| !cobertos.include?(d) } || 1
    end

    def plantao_periodo_for_cartaz
      @plantao
    end
  end
end
