# frozen_string_literal: true

module Admin
  class RegistrosEsportulaController < Admin::BaseController
    before_action :set_registro, only: [:show, :edit, :update, :destroy]

    def index
      scope = RegistroEsportula.joins(:sacerdote).includes(:sacerdote)
      scope = busca_em(scope, %w[sacerdotes.nome])
      scope = scope.where(status: params[:status]) if RegistroEsportula::STATUS.include?(params[:status])
      scope = scope.where(sacerdote_id: params[:sacerdote_id]) if params[:sacerdote_id].present?
      @registros = scope.order(created_at: :desc).page(params[:page])
    end

    def competencia
      @competencias = CompetenciaMensal.ordenados.limit(48)
      @competencia = resolve_competencia_para_esportulas
      return if @competencia.blank?

      load_esportulas_competencia_dados(@competencia)
    end

    def toggle_evento_pago
      evento = EventoEscala.find(params[:evento_escala_id])
      pago = params[:pago].to_s == "1"
      RegistroEsportula.sync_pago_from_evento!(evento, pago: pago)
      preparar_resposta_toggle_evento!(evento)

      respond_to do |format|
        format.turbo_stream
        format.html do
          redirect_to competencia_admin_registros_esportula_index_path(competencia_mensal_id: evento.competencia_mensal_id),
            notice: (pago ? "Espórtula marcada como paga." : "Pagamento desmarcado (pendente).")
        end
      end
    rescue ArgumentError => e
      responder_erro_toggle_evento(evento, e.message)
    rescue ActiveRecord::RecordInvalid => e
      responder_erro_toggle_evento(evento, e.record.errors.full_messages.to_sentence)
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def show
    end

    def new
      attrs = { data: Date.current }
      if params[:competencia_ano].present? && params[:competencia_mes].present?
        attrs[:competencia_ano] = params[:competencia_ano].to_i
        attrs[:competencia_mes] = params[:competencia_mes].to_i
      end
      @registro = RegistroEsportula.new(attrs)
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

    def load_esportulas_competencia_dados(competencia)
      @eventos = eventos_esportula_da_competencia(competencia)
      @resumo_eventos_map = helpers.esportula_resumo_eventos_map(@eventos)
      @resumo_por_sacerdote, @resumo_totais = EsportulasCompetenciaResumo.call(competencia)
    end

    def preparar_resposta_toggle_evento!(evento)
      evento.reload
      @competencia = evento.competencia_mensal
      @eventos = eventos_esportula_da_competencia(@competencia)
      @resumo_eventos_map = helpers.esportula_resumo_eventos_map(@eventos)
      @resumo_por_sacerdote, @resumo_totais = EsportulasCompetenciaResumo.call(@competencia)
      @resumo_linha = @resumo_por_sacerdote.find { |l| l[:sacerdote].id == evento.sacerdote_id } if evento.sacerdote_id.present?
    end

    def responder_erro_toggle_evento(evento, mensagem)
      return head(:not_found) if evento.nil?

      preparar_resposta_toggle_evento!(evento)
      flash.now[:alert] = mensagem
      respond_to do |format|
        format.turbo_stream { render :toggle_evento_pago, status: :unprocessable_entity }
        format.html do
          redirect_to competencia_admin_registros_esportula_index_path(competencia_mensal_id: evento.competencia_mensal_id),
            alert: mensagem
        end
      end
    end

    def eventos_esportula_da_competencia(competencia)
      lista = competencia.evento_escalas
        .nao_cancelados
        .includes(:tipo_servico, :sacerdote, :registro_esportulas)
        .order(:data, :horario)
        .to_a
      lista.select { |e| e.valor_esportula.to_d.positive? }
    end

    def resolve_competencia_para_esportulas
      if params[:competencia_mensal_id].present?
        return CompetenciaMensal.find_by(id: params[:competencia_mensal_id])
      end

      CompetenciaMensal.find_by(ano: Date.current.year, mes: Date.current.month) ||
        CompetenciaMensal.ordenados.first
    end

  end
end
