# frozen_string_literal: true

module LiturgiaCartazHelper
  MOLDURA_TEMPLATE_PATH = Rails.root.join("app/assets/images/cartaz/liturgia-moldura-mesc-template.jpg").freeze
  MOLDURA_PATH = Rails.root.join("app/assets/images/cartaz/liturgia-moldura.jpg").freeze
  MOLDURA_2X_PATH = Rails.root.join("app/assets/images/cartaz/liturgia-moldura-2x.jpg").freeze
  MOLDURA_1080_JPG = Rails.root.join("app/assets/images/cartaz/liturgia-moldura-1080.jpg").freeze
  MOLDURA_1080_PNG = Rails.root.join("app/assets/images/cartaz/liturgia-moldura-1080.png").freeze

  # Largura lógica do cartaz (px). Export v1 usa 2× moldura + viewport maior para PNG nítido.
  CANVAS_BASE_WIDTH = 576
  CANVAS_BASE_HEIGHT = 1024
  EXPORT_SCALE = 2

  MESC_V2_WIDTH = 1080
  MESC_V2_HEIGHT = 1920
  # Proporção da arte MESC original (576×1024) ampliada para WhatsApp 9:16.
  MESC_V2_SCALE = MESC_V2_WIDTH.to_f / CANVAS_BASE_WIDTH

  def liturgia_cartaz_canvas_width(scale = 1)
    (CANVAS_BASE_WIDTH * scale).to_i
  end

  def liturgia_cartaz_canvas_height(scale = 1)
    (CANVAS_BASE_HEIGHT * scale).to_i
  end

  def liturgia_mesc_moldura_path
    @liturgia_mesc_moldura_path ||= begin
      return MOLDURA_1080_PNG if File.exist?(MOLDURA_1080_PNG)
      return MOLDURA_1080_JPG if File.exist?(MOLDURA_1080_JPG)

      MOLDURA_PATH
    end
  end

  def liturgia_mesc_moldura_data_uri
    path = liturgia_mesc_moldura_path
    stamp = path.exist? ? File.mtime(path).to_i : 0
    @liturgia_mesc_moldura_data_uris ||= {}
    @liturgia_mesc_moldura_data_uris[stamp] ||= moldura_data_uri_for(path)
  end

  def liturgia_cartaz_moldura_data_uri(scale: 1)
    cache_key = scale >= EXPORT_SCALE ? :moldura_2x : :moldura_1x
    @liturgia_cartaz_moldura_data_uris ||= {}
    @liturgia_cartaz_moldura_data_uris[cache_key] ||= begin
      path = moldura_path_for(scale)
      bytes = File.binread(path)
      mime = path.to_s.end_with?(".png") ? "image/png" : "image/jpeg"
      "data:#{mime};base64,#{Base64.strict_encode64(bytes)}"
    end
  end

  def liturgia_cartaz_imagem_santo_data_uri(liturgia_dia)
    return unless liturgia_dia.imagem_santo.attached?

    att = liturgia_dia.imagem_santo
    bytes = att.download
    mime = att.content_type.presence || "image/jpeg"
    "data:#{mime};base64,#{Base64.strict_encode64(bytes)}"
  rescue StandardError => e
    Rails.logger.warn("[LiturgiaCartaz] Santo inline #{liturgia_dia.data}: #{e.message}")
    nil
  end

  def app_host
    host = ENV["APP_HOST"].presence || ENV["DEFAULT_URL_HOST"].presence
    return host if host.present?

    opts = Rails.application.config.action_mailer.default_url_options
    return "#{opts[:host]}:#{opts[:port]}" if opts&.dig(:host).present? && opts[:port].present?
    return opts[:host].to_s if opts&.dig(:host).present?

    "localhost:3033"
  end

  # Host para URLs no preview (navegador do admin). Export Grover usa app_host + embed base64.
  def liturgia_cartaz_preview_host
    if defined?(request) && request.present?
      request.host_with_port
    else
      app_host.delete_prefix("https://").delete_prefix("http://")
    end
  end

  def liturgia_cartaz_blob_url(attachment)
    return unless attachment.attached?

    protocol = if defined?(request) && request.present?
                 request.protocol.delete_suffix("://")
               else
                 Rails.env.production? ? "https" : "http"
               end
    host = liturgia_cartaz_preview_host
    host = host.delete_prefix("https://").delete_prefix("http://")
    rails_blob_url(attachment, host: host, protocol: protocol)
  end

  def liturgia_cartaz_runtime_status
    moldura = liturgia_mesc_moldura_path
    {
      renderer: Liturgia::CartazRenderer.v2? ? "v2" : "v1 (legacy)",
      moldura: moldura.basename.to_s,
      moldura_mtime: moldura.exist? ? File.mtime(moldura).strftime("%d/%m/%Y %H:%M") : "—",
      font_scale: ENV.fetch("LITURGIA_CARTAZ_FONT_SCALE", "1.1"),
      export_dpr: Liturgia::CartazV2PngGenerator.export_device_scale_factor,
      canvas: "#{MESC_V2_WIDTH}×#{MESC_V2_HEIGHT}"
    }
  end

  # Evita o navegador mostrar PNG antigo após regerar (mesmo filename, blob novo).
  def liturgia_cartaz_whatsapp_path(liturgia_dia)
    attachment = liturgia_dia.cartaz_whatsapp_instituicao
    return unless attachment&.attached?

    blob = attachment.blob
    stamp = blob.created_at.to_i
    "#{rails_blob_path(attachment, only_path: true)}?v=#{stamp}"
  end

  private

  def moldura_path_for(scale)
    if scale >= EXPORT_SCALE && File.exist?(MOLDURA_2X_PATH)
      MOLDURA_2X_PATH
    else
      MOLDURA_PATH
    end
  end

  def moldura_data_uri_for(path)
    bytes = File.binread(path)
    mime = path.to_s.end_with?(".png") ? "image/png" : "image/jpeg"
    "data:#{mime};base64,#{Base64.strict_encode64(bytes)}"
  end
end
