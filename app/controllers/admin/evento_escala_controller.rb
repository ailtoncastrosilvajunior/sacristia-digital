# frozen_string_literal: true

module Admin
  class EventoEscalaController < Admin::BaseController
    include Admin::ReturnToRedirect
    before_action :set_evento_completo, only: [:show]
    before_action :set_evento, only: [:edit, :update, :destroy, :escalar_ministros, :update_escalar_ministros]
    before_action :set_competencia, only: [:new, :create]

    def show
      if request.headers["Turbo-Frame"] == "evento_drawer"
        render partial: "show_drawer", layout: false
      elsif turbo_frame_request?
        render partial: "show_modal", layout: false
      end
    end

    def new
      @evento = @competencia.evento_escalas.build(
        data: params[:data].presence&.then { |d| Date.parse(d) } || @competencia.periodo,
        horario: params[:horario].presence || "08:00",
        quantidade_ministros: 2,
        tipo_escala: "ordinaria",
        status: "confirmado"
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
        aplicar_esportula_pos_save!(@evento, recalcular: true)
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
      @return_to = safe_return_to_path
      if turbo_frame_request?
        render partial: "form_modal", layout: false
      end
    end

    def update
      if @evento.update(evento_params)
        atualizar_coordenador(@evento)
        aplicar_esportula_pos_save!(@evento, recalcular: params[:recalcular_esportula_regra].present?)
        RegistroEsportula.sync_from_evento!(@evento)
        redirect_with_return_to(
          default: admin_competencia_mensal_path(@evento.competencia_mensal, filter_params),
          notice: "Evento atualizado com sucesso."
        )
      else
        @return_to = safe_return_to_path
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
      @escalar_return_params = filter_params
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
      EsportulaDestinatarioResolver.apply!(@evento) unless @evento.esportula_destinatario_manual?

      @evento.escala_ministros.update_all(coordenador: false, adoracao: false)
      if coord_id && ministro_ids.include?(coord_id)
        @evento.escala_ministros.find_by(ministro_id: coord_id)&.update_column(:coordenador, true)
      end
      if adoracao_id && ministro_ids.include?(adoracao_id)
        @evento.escala_ministros.find_by(ministro_id: adoracao_id)&.update_column(:adoracao, true)
      end

      if params[:escalar_context] == "page"
        redirect_to admin_competencia_mensal_path(@evento.competencia_mensal, filter_params), notice: "Escala atualizada com sucesso."
        return
      end

      respond_to do |format|
        format.turbo_stream do
          @filter_params_hash = filter_params
          @evento = EventoEscala.includes(:tipo_servico, :sacerdote, escala_ministros: :ministro).find(@evento.id)
          render :update_escalar_ministros
        end
        format.html do
          redirect_to admin_competencia_mensal_path(@evento.competencia_mensal, filter_params), notice: "Escala atualizada com sucesso."
        end
      end
    end

    private

    # Carrega tudo o que o drawer/ficha exibe em 1 consulta + 1 por associação (sem N+1).
    def set_evento_completo
      @evento = EventoEscala
        .includes(:tipo_servico, :sacerdote, { plantao_periodo: :ministros }, :competencia_mensal, escala_ministros: :ministro)
        .find(params[:id])
    end

    def set_evento
      @evento = EventoEscala.find(params[:id])
    end

    def set_competencia
      # No "new" vem na raiz da URL; no "create" o formulário envia aninhado em evento_escala[...]
      id = params[:competencia_mensal_id].presence || params.dig(:evento_escala, :competencia_mensal_id)
      @competencia = CompetenciaMensal.find(id)
    end

    def evento_params
      p = params.require(:evento_escala).permit(:competencia_mensal_id, :tipo_servico_id, :data, :horario,
        :quantidade_ministros, :local, :descricao, :observacoes, :sacerdote_id, :valor_esportula, :plantao_periodo_id, :status,
        :esportula_modo, :esportula_destinatario_tipo, :esportula_destinatario_sacerdote_id, :destinatario_esportula_id,
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

    def aplicar_esportula_pos_save!(evento, recalcular:)
      if recalcular
        evento.update!(esportula_destinatario_manual: false)
        EsportulaDestinatarioResolver.apply!(evento, force: true)
        return
      end

      if esportula_campos_no_form?
        normalizar_destinatario_evento!(evento)
        auto = EsportulaDestinatarioResolver.new(evento).compute_attributes
        manual = evento.esportula_modo != auto[:esportula_modo] ||
                 evento.esportula_destinatario_tipo != auto[:esportula_destinatario_tipo] ||
                 evento.destinatario_esportula_id != auto[:destinatario_esportula_id] ||
                 evento.esportula_destinatario_sacerdote_id != auto[:esportula_destinatario_sacerdote_id]
        evento.update!(esportula_destinatario_manual: manual) if evento.esportula_destinatario_manual? != manual
      elsif !evento.esportula_destinatario_manual?
        EsportulaDestinatarioResolver.apply!(evento)
      end
    end

    def esportula_campos_no_form?
      p = params[:evento_escala]
      return false unless p

      %w[esportula_modo esportula_destinatario_tipo destinatario_esportula_id esportula_destinatario_sacerdote_id].any? { |k| p.key?(k) }
    end

    def normalizar_destinatario_evento!(evento)
      if evento.esportula_destinatario_tipo == "instituicao"
        evento.update!(esportula_destinatario_sacerdote_id: nil)
      else
        evento.update!(destinatario_esportula_id: nil)
        if evento.esportula_destinatario_sacerdote_id.blank? && evento.sacerdote_id.present?
          evento.update!(esportula_destinatario_sacerdote_id: evento.sacerdote_id)
        end
      end
    end
  end
end
