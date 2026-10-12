# frozen_string_literal: true

module PainelMinistro
  # O ministro se oferece (ou retira a oferta) para apoiar o plantão de um dia.
  class OfertaApoiosController < PainelMinistro::BaseController
    def create
      data = Date.iso8601(params[:data].to_s)
      competencia = CompetenciaMensal.liberadas_para_ministros.find_by(ano: data.year, mes: data.month)
      return voltar(data, competencia, alert: "Escala deste mês ainda não liberada.") if competencia.nil? || data < Date.current

      bloco = competencia.plantao_para_dia(data)
      if bloco&.ministros&.exists?(current_user.ministro_id)
        return voltar(data, competencia, alert: "Você já está no plantão deste dia.")
      end

      oferta = competencia.oferta_apoios.find_or_initialize_by(ministro_id: current_user.ministro_id, data: data)
      oferta.status = "ativa"
      if oferta.save
        voltar(data, competencia, notice: "Apoio registrado. Você está no plantão deste dia como apoio.")
      else
        voltar(data, competencia, alert: oferta.errors.full_messages.to_sentence)
      end
    rescue Date::Error
      redirect_to ministro_escala_mensal_path, alert: "Data inválida."
    end

    def destroy
      oferta = OfertaApoio.where(ministro_id: current_user.ministro_id).find(params[:id])
      oferta.cancelar!
      voltar(oferta.data, oferta.competencia_mensal, notice: "Oferta de apoio retirada.")
    end

    private

    def voltar(data, competencia, **flash)
      redirect_to ministro_escala_mensal_path(competencia_mensal_id: competencia&.id, anchor: "dia-#{data.day}"), **flash
    end
  end
end
