# frozen_string_literal: true

module Admin
  class CalendarioBaseController < Admin::BaseController
    before_action :set_calendario_base, only: [:show, :edit, :update, :destroy]

    def index
      @calendario_base = CalendarioBase.ativos.order(:dia_da_semana, :horario)
    end

    def show
    end

    def new
      @calendario_base = CalendarioBase.new
    end

    def create
      @calendario_base = CalendarioBase.new(calendario_base_params)
      if @calendario_base.save
        redirect_to admin_calendario_base_index_path, notice: "Entrada do calendário base criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @calendario_base.update(calendario_base_params)
        redirect_to admin_calendario_base_index_path, notice: "Calendário base atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @calendario_base.destroy
      redirect_to admin_calendario_base_index_path, notice: "Entrada removida do calendário base."
    end

    private

    def set_calendario_base
      @calendario_base = CalendarioBase.find(params[:id])
    end

    def calendario_base_params
      params.require(:calendario_base).permit(:dia_da_semana, :horario, :tipo, :quantidade_ministros, :sacerdote_id, :valor_esportula_override, :ativo, :observacoes)
    end
  end
end
