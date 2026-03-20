# frozen_string_literal: true

module Admin
  class EventoEscalaController < Admin::BaseController
    before_action :set_evento, only: [:show, :edit, :update]
    before_action :set_competencia, only: [:new, :create]

    def show
    end

    def new
      @evento = @competencia.evento_escalas.build(
        data: params[:data].presence&.then { |d| Date.parse(d) } || @competencia.periodo,
        horario: params[:horario].presence || "08:00",
        quantidade_ministros: 2,
        tipo_escala: "ordinaria",
        status: "pendente"
      )
      @evento.tipo_servico = TipoServico.ativos.ordinarios.first if TipoServico.ativos.ordinarios.any?

      if turbo_frame_request?
        render partial: "form_new_modal", layout: false
      end
    end

    def create
      @evento = @competencia.evento_escalas.build(evento_params)
      if @evento.save
        redirect_to admin_competencia_mensal_path(@competencia, filter_params), notice: "Evento criado com sucesso."
      else
        if turbo_frame_request?
          render partial: "form_new_modal", layout: false, status: :unprocessable_entity
        else
          render :new, status: :unprocessable_entity
        end
      end
    end

    def edit
      if turbo_frame_request?
        render partial: "form_modal", layout: false
      end
    end

    def update
      if @evento.update(evento_params)
        redirect_to admin_competencia_mensal_path(@evento.competencia_mensal, filter_params), notice: "Evento atualizado com sucesso."
      else
        if turbo_frame_request?
          render partial: "form_modal", layout: false, status: :unprocessable_entity
        else
          render :edit, status: :unprocessable_entity
        end
      end
    end

    private

    def set_evento
      @evento = EventoEscala.find(params[:id])
    end

    def set_competencia
      @competencia = CompetenciaMensal.find(params[:competencia_mensal_id])
    end

    def evento_params
      params.require(:evento_escala).permit(:competencia_mensal_id, :tipo_servico_id, :data, :horario,
        :quantidade_ministros, :local, :descricao, :observacoes, :sacerdote_id, :valor_esportula, :equipe_id, :status,
        ministro_ids: [])
    end

    def filter_params
      params.permit(:tipo_servico_id, :sacerdote_id, :ministro_id).to_unsafe_h.compact_blank
    end
  end
end
