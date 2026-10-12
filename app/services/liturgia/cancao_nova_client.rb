# frozen_string_literal: true

require "nokogiri"

module Liturgia
  # Fonte principal: liturgia.cancaonova.com (HTML público; não há API oficial).
  # O endereço de cada dia é descoberto pelo calendário mensal do próprio site.
  class CancaoNovaClient
    BASE = "https://liturgia.cancaonova.com"
    AJAX = "#{BASE}/wp-admin/admin-ajax.php"
    NOME = "Canção Nova"

    TIPOS = {
      /\A1/ => "primeira_leitura",
      /salmo/i => "salmo",
      /\A2/ => "segunda_leitura",
      /evangelho/i => "evangelho"
    }.freeze

    Resultado = Struct.new(:titulo, :cor, :leituras, :url, keyword_init: true)

    def self.buscar(data)
      new.buscar(data)
    end

    def buscar(data)
      url = url_do_dia(data)
      raise Erro, "Dia #{data} não encontrado no calendário da Canção Nova" if url.blank?

      parse(Http.get(url), url)
    end

    private

    def url_do_dia(data)
      links_do_mes(data.year, data.month)[data.day]
    end

    def links_do_mes(ano, mes)
      Rails.cache.fetch("liturgia/cancaonova/calendario/#{ano}-#{mes}", expires_in: 6.hours) do
        html = Http.post_form(AJAX, "action" => "widget-ajax", "sMes" => mes, "sAno" => ano,
                                    "title" => "", "type" => "liturgia", "ajax" => "true")
        Nokogiri::HTML(html).css("a[href*='sDia=']").each_with_object({}) do |a, mapa|
          href = a["href"]
          dia = href[/sDia=(\d+)/, 1]
          mapa[dia.to_i] = href if dia && href[/sMes=(\d+)/, 1].to_i == mes
        end
      end
    end

    def parse(html, url)
      doc = Nokogiri::HTML(html)
      leituras = doc.css("#leituraTab li").filter_map { |li| extrair_leitura(doc, li) }
      raise Erro, "Nenhuma leitura encontrada em #{url}" if leituras.empty?

      Resultado.new(
        titulo: doc.at_css("h1.entry-title")&.text.to_s.squish.presence,
        cor: doc.at_css(".cor-liturgica")&.text.to_s.sub(/cor lit[uú]rgica:/i, "").squish.presence,
        leituras: leituras,
        url: url
      )
    end

    def extrair_leitura(doc, li)
      rotulo = li.at_css("label")&.text.to_s.squish
      referencia = li.at_css(".referencia")&.text.to_s.squish
      alvo = li.at_css("a")&.[]("href").to_s.delete_prefix("#")
      painel = doc.at_css("##{alvo}") if alvo.present?
      return if painel.nil?

      {
        "tipo" => tipo_para(rotulo),
        "rotulo" => rotulo,
        "referencia" => referencia,
        "texto" => texto_do_painel(painel, referencia)
      }
    end

    def tipo_para(rotulo)
      TIPOS.each { |regex, tipo| return tipo if rotulo.match?(regex) }
      rotulo.parameterize(separator: "_")
    end

    def texto_do_painel(painel, referencia)
      painel = painel.dup
      painel.css(".embeds-audio, iframe, script, style").remove
      painel.css("br").each { |br| br.replace("\n") }
      # Números de versículo (<strong>22</strong>) poluem a leitura em voz alta.
      painel.css("strong, b, sup").each { |n| n.remove if n.text.strip.match?(/\A\d+[a-z]?\z/) }

      paragrafos = painel.css("p").map { |p| p.text.gsub(/[ \t\u00a0]+/, " ").gsub(/ *\n */, "\n").strip }.reject(&:blank?)
      # O 1º parágrafo é o cabeçalho "Primeira Leitura (Gl 3,22-29)" repetindo a referência.
      cabecalho = paragrafos.first.to_s
      if cabecalho.length < 120 && (cabecalho.match?(/\A(primeira leitura|segunda leitura|respons[oó]rio|evangelho)\b/i) || (referencia.present? && cabecalho.include?(referencia)))
        paragrafos.shift
      end
      paragrafos.join("\n\n")
    end
  end
end
