# frozen_string_literal: true

# Libera hosts para ActionDispatch::HostAuthorization depois do boot completo.
#
# Motivo: se RAILS_ENV no deploy não for "production", config/environments/production.rb
# não roda e o config.hosts de lá é ignorado — daí "Blocked host" mesmo com a linha no arquivo.
#
# Configure no painel (DigitalOcean App Platform, etc.):
#   RAILS_ENV=production
#   APP_HOST=sacristia-digital-app-2df7e.ondigitalocean.app   (já usado no mailer)
# Opcional — lista extra separada por vírgula:
#   ALLOWED_HOSTS=meudominio.com.br,www.meudominio.com.br
Rails.application.config.after_initialize do
  raw = []
  raw.concat(ENV.fetch("ALLOWED_HOSTS", "").split(",").map(&:strip))

  app_host = ENV["APP_HOST"].to_s.strip
  if app_host.present?
    host =
      if app_host.match?(%r{\Ahttps?://}i)
        URI.parse(app_host).host
      else
        app_host.split("/").first&.split(":")&.first
      end
    raw << host if host.present?
  end

  # URL do App Platform: fora de teste sempre, para cobrir deploy com RAILS_ENV errado.
  raw << "sacristia-digital-app-2df7e.ondigitalocean.app" unless Rails.env.test?

  raw.compact.uniq.reject(&:blank?).each do |h|
    Rails.application.config.hosts << h
  end
end
