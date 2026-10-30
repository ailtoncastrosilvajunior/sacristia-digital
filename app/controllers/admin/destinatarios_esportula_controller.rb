# frozen_string_literal: true

module Admin
  class DestinatariosEsportulaController < Admin::BaseController
    before_action :set_destinatario, only: [:edit, :update]

    def index
      @destinatarios = DestinatarioEsportula.order(:nome)
    end

    def new
      @destinatario = DestinatarioEsportula.new(ativo: true)
    end

    def create
      @destinatario = DestinatarioEsportula.new(destinatario_params)
      if @destinatario.save
        redirect_to admin_destinatarios_esportula_index_path, notice: "Destinatário criado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @destinatario.update(destinatario_params)
        redirect_to admin_destinatarios_esportula_index_path, notice: "Destinatário atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_destinatario
      @destinatario = DestinatarioEsportula.find(params[:id])
    end

    def destinatario_params
      params.require(:destinatario_esportula).permit(:nome, :ativo, :observacoes)
    end
  end
end
