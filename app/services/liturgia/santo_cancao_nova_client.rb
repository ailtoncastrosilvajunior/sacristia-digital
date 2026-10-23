# frozen_string_literal: true

require "nokogiri"

module Liturgia
  # Santo do dia: santo.cancaonova.com (HTML público; calendário mensal via AJAX).
  class SantoCancaoNovaClient
    BASE = "https://santo.cancaonova.com"
    AJAX = "#{BASE}/wp-admin/admin-ajax.php"
    NOME = "Canção Nova — Santo do Dia"

    Resultado = Struct.new(:nome, :descricao, :imagem_url, :url, keyword_init: true)

    def self.buscar(data)
      new.buscar(data)
    end

    def buscar(data)
      url = url_do_dia(data)
      raise Erro, "Santo do dia #{data} não encontrado no calendário da Canção Nova" if url.blank?

      parse(Http.get(url), url)
    end

    private

    def url_do_dia(data)
      links_do_mes(data.year, data.month)[data.day]
    end

    def links_do_mes(ano, mes)
      Rails.cache.fetch("liturgia/cancaonova/santo/calendario/#{ano}-#{mes}", expires_in: 6.hours) do
        html = Http.post_form(AJAX, "action" => "widget-ajax", "sMes" => mes, "sAno" => ano,
                                    "title" => "", "type" => "santo", "ajax" => "true")
        Nokogiri::HTML(html).css("a[href*='sDia=']").each_with_object({}) do |a, mapa|
          href = a["href"]
          dia = href[/sDia=(\d+)/, 1]
          mapa[dia.to_i] = href if dia && href[/sMes=(\d+)/, 1].to_i == mes
        end
      end
    end

    def parse(html, url)
      doc = Nokogiri::HTML(html)
      nome = doc.at_css("h1.entry-title span")&.text.to_s.squish.presence ||
             doc.at_css("h1.entry-title")&.text.to_s.squish.presence
      raise Erro, "Nome do santo não encontrado em #{url}" if nome.blank?

      Resultado.new(
        nome: nome,
        descricao: extrair_descricao(doc),
        imagem_url: url_imagem(doc),
        url: url
      )
    end

    def extrair_descricao(doc)
      bloco = doc.at_css(".entry-content.content-santo")
      return if bloco.nil?

      bloco = bloco.dup
      bloco.css("img, ul#share-buttons, script, style").remove
      bloco.css("p").map { |p| p.text.gsub(/[ \t\u00a0]+/, " ").squish }
           .find { |t| t.length >= 40 }
           &.truncate(800)
    end

    def url_imagem(doc)
      url = doc.at_css('meta[property="og:image"]')&.[]("content").to_s.squish.presence
      url ||= doc.at_css(".entry-content.content-santo img")&.[]("src").to_s.squish.presence
      return if url.blank?

      url_imagem_grande(url)
    end

    # Miniaturas WordPress (ex.: foto-300x225.jpg) → foto.jpg
    def url_imagem_grande(url)
      url.sub(/-\d+x\d+(\.[a-zA-Z0-9]+(?:\?.*)?)\z/, '\1')
    end
  end
end
