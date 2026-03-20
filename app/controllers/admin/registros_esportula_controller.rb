# frozen_string_literal: true

module Admin
  class RegistrosEsportulaController < Admin::BaseController
    before_action :set_registro, only: [:show, :edit, :update, :destroy]

    def index
      @registros = RegistroEsportula.includes(:sacerdote).order(created_at: :desc).page(params[:page])
    end

    def show
    end

    def new
      @registro = RegistroEsportula.new(data: Date.current)
    end

    def create
      @registro = RegistroEsportula.new(registro_params)
      if @registro.save
        redirect_to admin_registro_esportula_path(@registro), notice: "Registro de espórtula criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @registro.update(registro_params)
        redirect_to admin_registro_esportula_path(@registro), notice: "Registro atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @registro.destroy
      redirect_to admin_registros_esportula_index_path, notice: "Registro removido com sucesso."
    end

    private

    def set_registro
      @registro = RegistroEsportula.find(params[:id])
    end

    def registro_params
      params.require(:registro_esportula).permit(:sacerdote_id, :evento_escala_id, :data, :forma_pagamento, :valor, :status, :competencia_ano, :competencia_mes)
    end
  end
end
