# frozen_string_literal: true

module LiturgiaCartazHelper
  MOLDURA_PATH = Rails.root.join("app/assets/images/cartaz/liturgia-moldura.jpg").freeze

  def liturgia_cartaz_moldura_data_uri
    @liturgia_cartaz_moldura_data_uri ||= begin
      bytes = File.binread(MOLDURA_PATH)
      "data:image/jpeg;base64,#{Base64.strict_encode64(bytes)}"
    end
  end

  def app_host
    host = ENV["APP_HOST"].presence || ENV["DEFAULT_URL_HOST"].presence
    return host if host.present?

    opts = Rails.application.config.action_mailer.default_url_options
    return "#{opts[:host]}:#{opts[:port]}" if opts&.dig(:host).present? && opts[:port].present?
    return opts[:host].to_s if opts&.dig(:host).present?

    "localhost:3033"
  end

  def liturgia_cartaz_blob_url(attachment)
    return unless attachment.attached?

    protocol = Rails.env.production? ? "https" : "http"
    host = app_host
    host = host.delete_prefix("https://").delete_prefix("http://")
    rails_blob_url(attachment, host: host, protocol: protocol)
  end
end
