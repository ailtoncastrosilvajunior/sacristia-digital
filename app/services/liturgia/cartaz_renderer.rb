# frozen_string_literal: true

module Liturgia
  # Escolhe o renderizador de PNG (v1 = moldura JPG; v2 = HTML/CSS 1080×1920).
  class CartazRenderer
    def self.v2?
      ENV.fetch("LITURGIA_CARTAZ_RENDERER", "legacy") == "v2"
    end

    def self.attach!(liturgia_dia)
      if v2?
        CartazV2PngGenerator.attach!(liturgia_dia)
      else
        CartazPngGenerator.new(liturgia_dia).attach!
      end
    end
  end
end
