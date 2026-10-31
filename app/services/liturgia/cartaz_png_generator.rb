# frozen_string_literal: true

require "grover"

module Liturgia
  class CartazPngGenerator
    include LiturgiaCartazHelper

    class Erro < StandardError; end

    # Canvas lógico 1152×2048 (moldura 2×); deviceScaleFactor 2 → PNG ~2304×4096, texto nítido no WhatsApp.
    VIEWPORT = {
      width: CANVAS_BASE_WIDTH * EXPORT_SCALE,
      height: CANVAS_BASE_HEIGHT * EXPORT_SCALE,
      deviceScaleFactor: 2
    }.freeze

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
        viewport: VIEWPORT,
        full_page: false,
        selector: "#cartaz-poster-export",
        display_url: display_url,
        launch_args: ["--no-sandbox", "--disable-setuid-sandbox", "--font-render-hinting=none"],
        wait_until: "load",
        timeout: 120_000,
        delay: 800
      ).to_png

      raise Erro, "PNG vazio" if png.blank?

      png
    rescue Grover::JavaScript::Error, Grover::BrowserRunner::Error => e
      raise Erro, "Não foi possível gerar o PNG (Chrome/Grover): #{e.message}"
    end

    def attach!
      png = call
      filename = "escala-MESC-#{@liturgia.data.strftime('%d-%m-%Y')}-igmr-#{@cartaz.igmr_numero}.png"
      # Substitui o arquivo anterior (sem isso alguns backends mantêm o blob antigo visível no cache).
      @liturgia.cartaz_whatsapp.purge if @liturgia.cartaz_whatsapp.attached?
      @liturgia.cartaz_whatsapp.attach(
        io: StringIO.new(png),
        filename: filename,
        content_type: "image/png"
      )
      @liturgia.touch
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
