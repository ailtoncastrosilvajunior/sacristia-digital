# frozen_string_literal: true

module Admin
  class SacerdotesController < Admin::BaseController
    before_action :set_sacerdote, only: [:show, :edit, :update, :destroy]

    def index
      @sacerdotes = Sacerdote.ordenados_por_nome.page(params[:page])
    end

    def show
    end

    def new
      @sacerdote = Sacerdote.new
    end

    def create
      @sacerdote = Sacerdote.new(sacerdote_params)
      if @sacerdote.save
        redirect_to admin_sacerdote_path(@sacerdote), notice: "Sacerdote cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @sacerdote.update(sacerdote_params)
        redirect_to admin_sacerdote_path(@sacerdote), notice: "Sacerdote atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @sacerdote.destroy
      redirect_to admin_sacerdotes_path, notice: "Sacerdote removido com sucesso."
    end

    private

    def set_sacerdote
      @sacerdote = Sacerdote.find(params[:id])
    end

    def sacerdote_params
      params.require(:sacerdote).permit(:nome, :email, :telefone, :forma_esportula, :valor_esportula_padrao, :ativo)
    end
  end
end
