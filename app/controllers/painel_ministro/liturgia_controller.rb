# frozen_string_literal: true

module PainelMinistro
  class LiturgiaController < PainelMinistro::BaseController
    # Lista os dias já validados do mês; por padrão abre o dia de hoje (se validado).
    def index
      @mes = parse_mes(params[:mes])
      @dias = LiturgiaDia.validadas
                         .where(data: @mes.beginning_of_month..@mes.end_of_month)
                         .order(:data)
                         .index_by(&:data)
      @hoje = @dias[Date.current]
    end

    def show
      data = Date.iso8601(params[:data])
      @liturgia = LiturgiaDia.validadas.with_attached_imagem_santo.find_by(data: data)
      @data = data
      @anterior = LiturgiaDia.validadas.where(data: ...data).order(data: :desc).first
      @proximo = LiturgiaDia.validadas.where(data: (data + 1)..).order(:data).first
      @eventos_do_dia = eventos_do_ministro(data)

      render :sem_liturgia, status: :not_found if @liturgia.nil?
    rescue Date::Error
      redirect_to ministro_liturgia_index_path, alert: "Data inválida."
    end

    private

    def parse_mes(raw)
      Date.strptime("#{raw}-01", "%Y-%m-%d")
    rescue ArgumentError, TypeError
      Date.current.beginning_of_month
    end

    def eventos_do_ministro(data)
      ministro = current_user.ministro
      return [] if ministro.blank?

      EventoEscala
        .joins(:escala_ministros, :competencia_mensal)
        .where(data: data, escala_ministros: { ministro_id: ministro.id }, competencia_mensal: { escala_liberada: true })
        .includes(:tipo_servico, :sacerdote)
        .distinct
        .order(:horario)
        .reject(&:cancelado?)
    end
  end
end
