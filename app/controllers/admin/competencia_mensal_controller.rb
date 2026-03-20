# frozen_string_literal: true

module Admin
  class CompetenciaMensalController < Admin::BaseController
    before_action :set_competencia, only: [:show, :edit, :update, :destroy, :gerar_escala, :regenerar_escala]

    def index
      @competencias = CompetenciaMensal.ordenados

      @competencias = @competencias.where(ano: params[:ano]) if params[:ano].present?
      @competencias = @competencias.where(mes: params[:mes]) if params[:mes].present?
      @competencias = @competencias.where(escala_gerada: params[:escala_gerada]) if params[:escala_gerada].present?

      @competencias = @competencias.page(params[:page])
    end

    def show
      @eventos = @competencia.evento_escalas.includes(:tipo_servico, :sacerdote, :ministros)

      @eventos = @eventos.where(tipo_servico_id: params[:tipo_servico_id]) if params[:tipo_servico_id].present?
      @eventos = @eventos.where(sacerdote_id: params[:sacerdote_id]) if params[:sacerdote_id].present?
      @eventos = @eventos.joins(:escala_ministros).where(escala_ministros: { ministro_id: params[:ministro_id] }).distinct if params[:ministro_id].present?
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

    def set_competencia
      @competencia = CompetenciaMensal.find(params[:id])
    end

    def competencia_params
      params.require(:competencia_mensal).permit(:ano, :mes)
    end
  end
end
