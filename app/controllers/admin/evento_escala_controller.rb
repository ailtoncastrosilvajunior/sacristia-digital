# frozen_string_literal: true

module Admin
  class EventoEscalaController < Admin::BaseController
    before_action :set_evento, only: [:show, :edit, :update, :destroy, :escalar_ministros, :update_escalar_ministros]
    before_action :set_competencia, only: [:new, :create]

    def show
      if turbo_frame_request?
        render partial: "show_modal", layout: false
      end
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
        atualizar_coordenador(@evento)
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
        atualizar_coordenador(@evento)
        redirect_to admin_competencia_mensal_path(@evento.competencia_mensal, filter_params), notice: "Evento atualizado com sucesso."
      else
        if turbo_frame_request?
          render partial: "form_modal", layout: false, status: :unprocessable_entity
        else
          render :edit, status: :unprocessable_entity
        end
      end
    end

    def destroy
      competencia = @evento.competencia_mensal
      @evento.destroy
      redirect_to admin_competencia_mensal_path(competencia, filter_params), notice: "Evento excluído com sucesso."
    end

    def escalar_ministros
      @ministros_disponiveis = Ministro.ativos.ordenados_por_nome
      @ministros_escalados = @evento.escala_ministros.includes(:ministro).order(coordenador: :desc, adoracao: :desc)
      @sacerdotes = Sacerdote.ativos.ordenados_por_nome
      if turbo_frame_request?
        render partial: "escalar_modal", layout: false
      end
    end

    def update_escalar_ministros
      ministro_ids = (params[:ministro_ids] || []).reject(&:blank?).map(&:to_i).uniq
      coord_id = params[:ministro_coordenador_id].to_s.presence&.to_i
      adoracao_id = params[:ministro_adoracao_id].to_s.presence&.to_i
      sacerdote_id = params[:sacerdote_id].to_s.presence
      sacerdote_id = nil if sacerdote_id == "none" || sacerdote_id.blank?
      sacerdote_id = sacerdote_id.to_i if sacerdote_id.present?

      @evento.sacerdote_id = sacerdote_id
      @evento.ministro_ids = ministro_ids
      @evento.save!

      @evento.escala_ministros.update_all(coordenador: false, adoracao: false)
      if coord_id && ministro_ids.include?(coord_id)
        @evento.escala_ministros.find_by(ministro_id: coord_id)&.update_column(:coordenador, true)
      end
      if adoracao_id && ministro_ids.include?(adoracao_id)
        @evento.escala_ministros.find_by(ministro_id: adoracao_id)&.update_column(:adoracao, true)
      end

      redirect_to admin_competencia_mensal_path(@evento.competencia_mensal, aba: "lista"), notice: "Escala atualizada com sucesso."
    end

    private

    def set_evento
      @evento = EventoEscala.find(params[:id])
    end

    def set_competencia
      @competencia = CompetenciaMensal.find(params[:competencia_mensal_id])
    end

    def evento_params
      p = params.require(:evento_escala).permit(:competencia_mensal_id, :tipo_servico_id, :data, :horario,
        :quantidade_ministros, :local, :descricao, :observacoes, :sacerdote_id, :valor_esportula, :equipe_id, :status,
        ministro_ids: [])
      p[:ministro_ids] = (p[:ministro_ids] || []).reject(&:blank?)
      p
    end

    def atualizar_coordenador(evento)
      coord_id = params.dig(:evento_escala, :ministro_coordenador_id).to_s.presence&.to_i
      evento.escala_ministros.update_all(coordenador: false)
      if coord_id && evento.ministro_ids.include?(coord_id)
        evento.escala_ministros.find_by(ministro_id: coord_id)&.update_column(:coordenador, true)
      end
    end

    def filter_params
      params.permit(:tipo_servico_id, :sacerdote_id, :ministro_id, :dia_semana, :vista, :aba, :vista_calendario, :data_ref).to_unsafe_h.compact_blank
    end
  end
end
