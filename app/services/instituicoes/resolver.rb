# frozen_string_literal: true

module Instituicoes
  # Resolve a instituição pelo host (subdomínio) ou fallback em desenvolvimento.
  class Resolver
    def self.call(request)
      new(request).call
    end

    def initialize(request)
      @request = request
    end

    def call
      slug = slug_from_host || slug_from_env
      return if slug.blank?

      Instituicao.ativas.find_by(slug: slug)
    end

    private

    def slug_from_host
      host = @request.host.to_s.downcase
      base = base_domain

      if base.present? && host.end_with?(".#{base}")
        host.delete_suffix(".#{base}")
      elsif host.ends_with?(".localhost") || host.ends_with?(".lvh.me")
        host.split(".").first
      end
    end

    def slug_from_env
      return ENV["INSTITUICAO_SLUG"].presence if ENV["INSTITUICAO_SLUG"].present?

      # localhost / 127.0.0.1 sem subdomínio
      return "facedecristo" if Rails.env.development? && local_host?(@request.host)

      nil
    end

    def base_domain
      ENV.fetch("INSTITUICAO_BASE_DOMAIN", "sacristia-digital.net.br").downcase
    end

    def local_host?(host)
      host.in?(%w[localhost 127.0.0.1]) || host.end_with?(".local")
    end
  end
end
