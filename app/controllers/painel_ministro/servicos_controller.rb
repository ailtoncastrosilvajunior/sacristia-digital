# frozen_string_literal: true

module PainelMinistro
  class ServicosController < PainelMinistro::BaseController
    def index
      @servicos = eventos_do_ministro.por_data
    end

    def show
      @servico = eventos_do_ministro.find(params[:id])
    end

    def confirmar
      @servico = eventos_do_ministro.find(params[:id])
      em = @servico.escala_ministros.find_by!(ministro_id: current_user.ministro_id)
      em.confirmar!
      redirect_to ministro_servico_path(@servico), notice: "Presença confirmada."
    end

    private

    def eventos_do_ministro
      EventoEscala
        .joins(:escala_ministros)
        .where(escala_ministros: { ministro_id: current_user.ministro_id })
        .includes(:tipo_servico, :sacerdote, :equipe, escala_ministros: :ministro)
        .distinct
        .where.not(status: "cancelado")
    end
  end
end
