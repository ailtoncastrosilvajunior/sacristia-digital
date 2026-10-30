# frozen_string_literal: true

module Liturgia
  # Sequência diária de parágrafos da IGMR. Âncora: 31/10/2026 = n.º 51.
  # Após o último parágrafo cadastrado, recomeça do n.º 1.
  class IgmrRotacao
    ANCHOR_DATA = Date.new(2026, 10, 31)
    ANCHOR_NUMERO = 51

    def self.numero_para(data)
      new(data).numero
    end

    def initialize(data)
      @data = data.to_date
    end

    def numero
      sequencia = ANCHOR_NUMERO + (@data - ANCHOR_DATA).to_i
      limite = IgmrParagrafo::LIMITE_ROTACAO
      ((sequencia - 1) % limite) + 1
    end

    def paragrafo
      IgmrParagrafo.find_by(numero: numero)
    end
  end
end
