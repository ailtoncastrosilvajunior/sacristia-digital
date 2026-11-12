# frozen_string_literal: true

require "grover"

module Liturgia
  class CartazV2PngGenerator
    include LiturgiaCartazHelper

    class Erro < StandardError; end

    BASE_VIEWPORT = { width: MESC_V2_WIDTH, height: MESC_V2_HEIGHT }.freeze

    def self.attach!(liturgia_dia)
      new(liturgia_dia).attach!
    end

    def self.export_device_scale_factor
      ENV.fetch("LITURGIA_CARTAZ_EXPORT_DPR", "1").to_i.clamp(1, 3)
    end

    def initialize(liturgia_dia)
      @liturgia = liturgia_dia
      @cartaz = CartazBuilder.build(liturgia_dia, trecho_max: 140)
    end

    def attach!
      registro = CartazRegistroInstituicao.for!(@liturgia)
      png = call
      filename = "escala-MESC-#{@liturgia.data.strftime('%d-%m-%Y')}-igmr-#{@cartaz.igmr_numero}-v2.png"
      registro.cartaz_whatsapp.purge if registro.cartaz_whatsapp.attached?
      registro.cartaz_whatsapp.attach(
        io: StringIO.new(png),
        filename: filename,
        content_type: "image/png"
      )
      registro.touch
      registro
    end

    def call
      html = render_html
      dpr = self.class.export_device_scale_factor
      png = Grover.new(
        html,
        format: "png",
        viewport: BASE_VIEWPORT.merge(deviceScaleFactor: dpr),
        full_page: false,
        selector: "#mesc-card-export",
        display_url: display_url,
        launch_args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--font-render-hinting=medium",
          "--force-color-profile=srgb"
        ],
        wait_until: "load",
        wait_for: "document.querySelector('#mesc-card-export') && (!document.fonts || document.fonts.status === 'loaded')",
        timeout: 120_000,
        delay: 1_000
      ).to_png

      raise Erro, "PNG vazio" if png.blank?

      png
    rescue StandardError => e
      raise Erro, "Não foi possível gerar o PNG v2 (Chrome/Grover): #{e.message}"
    end

    private

    def render_html
      ApplicationController.render(
        template: "mesc_cards/export",
        layout: "mesc_card_export",
        assigns: {
          liturgia_dia: @liturgia,
          cartaz: @cartaz,
          export_embed: true,
          layout_warnings: CartazV2LayoutValidator.validate(@liturgia, @cartaz)
        }
      )
    end

    def display_url
      protocol = Rails.env.production? ? "https" : "http"
      host = app_host.delete_prefix("https://").delete_prefix("http://")
      "#{protocol}://#{host}/"
    end
  end
end
