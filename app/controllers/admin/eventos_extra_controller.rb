# frozen_string_literal: true

module Admin
  class EventosExtraController < Admin::BaseController
    before_action :set_evento, only: [:show, :edit, :update, :destroy]

    def index
      @eventos = EventoEscala.extras.por_data.page(params[:page])
    end

    def show
    end

    def new
      @evento = EventoEscala.new(tipo_escala: "extra", data: Date.current)
    end

    def create
      @evento = EventoEscala.new(evento_params.merge(tipo_escala: "extra"))
      if @evento.save
        redirect_to admin_eventos_extra_path(@evento), notice: "Evento extra criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @evento.update(evento_params)
        redirect_to admin_eventos_extra_path(@evento), notice: "Evento extra atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @evento.destroy
      redirect_to admin_eventos_extra_index_path, notice: "Evento extra removido com sucesso."
    end

    private

    def set_evento
      @evento = EventoEscala.find(params[:id])
    end

    def evento_params
      params.require(:evento_escala).permit(:competencia_mensal_id, :tipo_servico_id, :data, :horario, :quantidade_ministros, :local, :descricao, :observacoes, :sacerdote_id, :valor_esportula, :equipe_id, :status)
    end
  end
end
