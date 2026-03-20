# frozen_string_literal: true

module Admin
  class MinistrosController < Admin::BaseController
    before_action :set_ministro, only: [:show, :edit, :update, :destroy]

    def index
      @ministros = Ministro.ordenados_por_nome.page(params[:page])
    end

    def show
    end

    def new
      @ministro = Ministro.new
    end

    def create
      @ministro = Ministro.new(ministro_params)
      if @ministro.save
        redirect_to admin_ministro_path(@ministro), notice: "Ministro cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @ministro.update(ministro_params)
        redirect_to admin_ministro_path(@ministro), notice: "Ministro atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ministro.destroy
      redirect_to admin_ministros_path, notice: "Ministro removido com sucesso."
    end

    private

    def set_ministro
      @ministro = Ministro.find(params[:id])
    end

    def ministro_params
      params.require(:ministro).permit(:nome, :email, :telefone, :sexo, :ativo, :observacoes)
    end
  end
end
