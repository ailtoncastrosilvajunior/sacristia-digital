# frozen_string_literal: true

module Admin
  class CalendarioBaseController < Admin::BaseController
    before_action :set_calendario_base, only: [:show, :edit, :update, :destroy]

    def index
      scope = CalendarioBase.left_joins(:sacerdote).includes(:sacerdote, :destinatario_esportula)
      scope = busca_em(scope, %w[sacerdotes.nome])
      scope = case params[:status]
              when "inativo" then scope.where(ativo: false)
              when "todos" then scope
              else scope.where(ativo: true)
              end
      scope = scope.where(dia_da_semana: params[:dia_da_semana]) if params[:dia_da_semana].present?
      scope = scope.where(tipo: params[:tipo]) if CalendarioBase.tipos.key?(params[:tipo])
      @calendario_base = scope.order(:dia_da_semana, :horario)
      @por_dia = @calendario_base.group_by(&:dia_da_semana)
    end

    def show
    end

    def new
      @calendario_base = CalendarioBase.new
      dia = params[:dia_da_semana]
      @calendario_base.dia_da_semana = dia.to_i if dia.present? && (0..6).cover?(dia.to_i)
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
      params.require(:calendario_base).permit(:dia_da_semana, :horario, :tipo, :quantidade_ministros, :sacerdote_id,
        :valor_esportula_override, :ativo, :observacoes, :esportula_modo, :destinatario_esportula_id)
    end
  end
end
