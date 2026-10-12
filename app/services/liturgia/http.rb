# frozen_string_literal: true

require "net/http"

module Liturgia
  module Http
    USER_AGENT = "SacristiaDigital/1.0 (+uso interno paroquial)"

    module_function

    def get(url, limite_redirects: 3)
      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = USER_AGENT
      resposta = request(uri, req)
      seguir_redirect(resposta, uri, limite_redirects) || resposta_ok!(resposta, url)
    end

    def post_form(url, dados)
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri)
      req["User-Agent"] = USER_AGENT
      req.set_form_data(dados)
      resposta_ok!(request(uri, req), url)
    end

    def request(uri, req)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 15) do |http|
        http.request(req)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
      raise Erro, "Falha de rede ao acessar #{uri.host}: #{e.class}"
    end

    def seguir_redirect(resposta, uri, restantes)
      return nil unless resposta.is_a?(Net::HTTPRedirection)
      raise Erro, "Redirecionamentos demais" if restantes <= 0

      get(URI.join(uri, resposta["location"]).to_s, limite_redirects: restantes - 1)
    end

    def resposta_ok!(resposta, url)
      return resposta.body.to_s.dup.force_encoding("UTF-8") if resposta.is_a?(Net::HTTPSuccess)

      raise Erro, "HTTP #{resposta.code} em #{url}"
    end
  end
end
