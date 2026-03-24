# frozen_string_literal: true

module Admin
  class EquipesController < Admin::BaseController
    before_action :set_equipe, only: [:show, :edit, :update, :destroy]

    def index
      @equipes = Equipe.includes(:ministros).order(:nome)
    end

    def show
    end

    def new
      @equipe = Equipe.new
    end

    def create
      @equipe = Equipe.new(equipe_params)
      if @equipe.save
        redirect_to admin_equipe_path(@equipe), notice: "Equipe criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @equipe.update(equipe_params)
        redirect_to admin_equipe_path(@equipe), notice: "Equipe atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @equipe.destroy
      redirect_to admin_equipes_path, notice: "Equipe removida com sucesso."
    end

    private

    def set_equipe
      @equipe = Equipe.find(params[:id])
    end

    def equipe_params
      p = params.require(:equipe).permit(:nome, :observacoes, :dia_inicio, :dia_fim, ministro_ids: [])
      p[:ministro_ids] = (p[:ministro_ids] || []).reject(&:blank?).map(&:to_i)
      p
    end
  end
end
