# frozen_string_literal: true

require "grover"

module Esportulas
  class ReciboPdfGenerator
    class Erro < StandardError; end

    def self.call(competencia:, recibos:, paroquia_nome:, emitido_em: Time.current)
      new(competencia:, recibos:, paroquia_nome:, emitido_em:).call
    end

    def initialize(competencia:, recibos:, paroquia_nome:, emitido_em: Time.current)
      @competencia = competencia
      @recibos = recibos
      @paroquia_nome = paroquia_nome
      @emitido_em = emitido_em
    end

    def call
      html = render_html
      pdf = Grover.new(
        html,
        format: "A5",
        print_background: true,
        margin: { top: "6mm", bottom: "6mm", left: "7mm", right: "7mm" },
        display_url: display_url,
        wait_until: "load",
        timeout: 90_000,
        delay: 200
      ).to_pdf

      raise Erro, "PDF vazio" if pdf.blank?

      pdf
    rescue StandardError => e
      raise Erro, "Não foi possível gerar o PDF (Chrome/Grover): #{e.message}"
    end

    private

    def render_html
      ApplicationController.render(
        template: "admin/registros_esportula/recibo_esportula",
        layout: false,
        locals: {
          competencia: @competencia,
          recibos: @recibos,
          paroquia_nome: @paroquia_nome,
          emitido_em: @emitido_em
        }
      )
    end

    def display_url
      protocol = Rails.env.production? ? "https" : "http"
      host = ENV["APP_HOST"].presence || ENV["DEFAULT_URL_HOST"].presence || "localhost:3000"
      host = host.delete_prefix("https://").delete_prefix("http://")
      "#{protocol}://#{host}/"
    end
  end
end
