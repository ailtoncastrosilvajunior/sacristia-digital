# frozen_string_literal: true

require "json"

module Liturgia
  # Fonte de conferência: API pública liturgia.up.railway.app (não oficial).
  class UpApiClient
    BASE = "https://liturgia.up.railway.app/v2/"
    NOME = "liturgia.up.railway.app"

    CHAVES = {
      "primeiraLeitura" => ["primeira_leitura", "1ª Leitura"],
      "salmo" => ["salmo", "Salmo"],
      "segundaLeitura" => ["segunda_leitura", "2ª Leitura"],
      "evangelho" => ["evangelho", "Evangelho"]
    }.freeze

    Resultado = Struct.new(:titulo, :cor, :leituras, :url, keyword_init: true)

    def self.buscar(data)
      new.buscar(data)
    end

    def buscar(data)
      url = "#{BASE}?dia=#{data.day}&mes=#{data.month}&ano=#{data.year}"
      json = JSON.parse(Http.get(url))
      leituras = montar_leituras(json["leituras"] || {})
      raise Erro, "API sem leituras para #{data}" if leituras.empty?

      Resultado.new(titulo: json["liturgia"], cor: json["cor"], leituras: leituras, url: url)
    rescue JSON::ParserError
      raise Erro, "Resposta inválida da API de liturgia"
    end

    private

    def montar_leituras(bloco)
      CHAVES.flat_map do |chave, (tipo, rotulo)|
        Array(bloco[chave]).map do |item|
          {
            "tipo" => tipo,
            "rotulo" => rotulo,
            "referencia" => item["referencia"].to_s.squish,
            "texto" => item["texto"].to_s.squish
          }
        end
      end
    end
  end
end
