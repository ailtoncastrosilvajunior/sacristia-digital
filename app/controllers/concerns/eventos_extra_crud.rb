# frozen_string_literal: true

# CRUD de eventos extra compartilhado entre Admin e EscalaExtra.
# Os paths vêm de EventosExtraPathsHelper (conforme o namespace do controller).
module EventosExtraCrud
  extend ActiveSupport::Concern

  included do
    before_action :set_evento, only: [:show, :edit, :update, :destroy]
  end

  def index
    scope = EventoEscala.extras.joins(:tipo_servico).includes(:tipo_servico, :sacerdote, escala_ministros: :ministro)
    scope = busca_em(scope, %w[evento_escala.local tipo_servicos.nome])
    scope = scope.where(status: params[:status]) if EventoEscala::STATUS.include?(params[:status])
    scope = scope.where(tipo_servico_id: params[:tipo_servico_id]) if params[:tipo_servico_id].present?

    @aba = params[:aba] == "lista" ? "lista" : "calendario"
    @vista_calendario = %w[semana dia].include?(params[:vista_calendario]) ? params[:vista_calendario] : "mes"
    @data_ref = (params[:data_ref].presence && (Date.parse(params[:data_ref]) rescue nil)) || Date.current
    @domingo_semana = @data_ref - @data_ref.wday
    @inicio_mes = @data_ref.beginning_of_month
    @fim_mes = @data_ref.end_of_month

    @periodo = case @vista_calendario
               when "semana" then @domingo_semana..(@domingo_semana + 6)
               when "dia" then @data_ref..@data_ref
               else @inicio_mes..@fim_mes
               end
    @eventos_total = scope.count
    @eventos_lista = scope.where(data: @periodo).por_data.to_a
    @eventos_contagem = @eventos_lista.size
  end

  def show
  end

  def new
    data = params[:data].presence&.then { |d| Date.parse(d) } || Date.current
    competencia = params[:competencia_mensal_id].present? ? CompetenciaMensal.find_by(id: params[:competencia_mensal_id]) : competencia_mensal_atual
    @evento = EventoEscala.new(tipo_escala: "extra", data: data, competencia_mensal_id: competencia[:id])
    @evento.plantao_periodo_id = competencia.plantao_para_dia(data)&.id
  end

  def create
    @evento = EventoEscala.new(evento_params.merge(tipo_escala: "extra"))
    if @evento.save
      @evento.popular_escala_do_plantao!
      redirect_to helpers.evento_extra_path(@evento), notice: "Evento extra criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @evento.update(evento_params)
      redirect_to helpers.evento_extra_path(@evento), notice: "Evento extra atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @evento.destroy
    redirect_to helpers.eventos_extra_index_path, notice: "Evento extra removido com sucesso."
  end

  private

  # Campos liberados no formulário. Subclasses podem restringir (ex.: sem espórtula).
  def campos_permitidos
    %i[competencia_mensal_id tipo_servico_id data horario quantidade_ministros local descricao observacoes sacerdote_id valor_esportula plantao_periodo_id status]
  end

  def set_evento
    @evento = EventoEscala.extras.find(params[:id])
  end

  def evento_params
    params.require(:evento_escala).permit(*campos_permitidos)
  end

  def competencia_mensal_atual
    CompetenciaMensal.where(ano: Date.current.year, mes: Date.current.month).order(created_at: :desc).first
  end
end
