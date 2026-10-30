# frozen_string_literal: true

require "grover"

module Liturgia
  class CartazPngGenerator
    include LiturgiaCartazHelper

    class Erro < StandardError; end

    # Mesmas proporções do JPG-molde (576×1024); deviceScaleFactor 2 → PNG ~1152×2048.
    VIEWPORT = { width: 576, height: 1024 }.freeze

    def self.call(liturgia_dia)
      new(liturgia_dia).call
    end

    def initialize(liturgia_dia)
      @liturgia = liturgia_dia
      @cartaz = CartazBuilder.build(liturgia_dia)
    end

    def call
      html = render_html
      png = Grover.new(
        html,
        format: "png",
        viewport: VIEWPORT.merge(deviceScaleFactor: 2),
        display_url: display_url,
        launch_args: ["--no-sandbox", "--disable-setuid-sandbox"],
        wait_until: "load",
        timeout: 90_000
      ).to_png

      raise Erro, "PNG vazio" if png.blank?

      png
    rescue Grover::JavaScript::Error, Grover::BrowserRunner::Error => e
      raise Erro, "Não foi possível gerar o PNG (Chrome/Grover): #{e.message}"
    end

    def attach!
      png = call
      filename = "escala-MESC-#{@liturgia.data.strftime('%d-%m-%Y')}-igmr-#{@cartaz.igmr_numero}.png"
      @liturgia.cartaz_whatsapp.attach(
        io: StringIO.new(png),
        filename: filename,
        content_type: "image/png"
      )
      @liturgia
    end

    private

    def render_html
      ApplicationController.render(
        template: "admin/liturgia_dias/cartaz_export",
        layout: "liturgia_cartaz_export",
        assigns: { liturgia_dia: @liturgia, cartaz: @cartaz }
      )
    end

    def display_url
      protocol = Rails.env.production? ? "https" : "http"
      host = app_host
      host = host.delete_prefix("https://").delete_prefix("http://")
      "#{protocol}://#{host}/"
    end
  end
end
