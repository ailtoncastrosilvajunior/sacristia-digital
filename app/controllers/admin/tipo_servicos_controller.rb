# frozen_string_literal: true

module Admin
  class TipoServicosController < Admin::BaseController
    before_action :set_tipo_servico, only: [:show, :edit, :update, :destroy]

    def index
      @tipo_servicos = TipoServico.order(:tipo_escala, :nome).page(params[:page])
    end

    def show
    end

    def new
      @tipo_servico = TipoServico.new
    end

    def create
      @tipo_servico = TipoServico.new(tipo_servico_params)
      if @tipo_servico.save
        redirect_to admin_tipo_servico_path(@tipo_servico), notice: "Tipo de serviço cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tipo_servico.update(tipo_servico_params)
        redirect_to admin_tipo_servico_path(@tipo_servico), notice: "Tipo de serviço atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tipo_servico.destroy
      redirect_to admin_tipo_servicos_path, notice: "Tipo de serviço removido com sucesso."
    end

    private

    def set_tipo_servico
      @tipo_servico = TipoServico.find(params[:id])
    end

    def tipo_servico_params
      params.require(:tipo_servico).permit(:nome, :tipo_escala, :cor_etiqueta, :ativo)
    end
  end
end
