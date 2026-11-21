# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false

  # Polling para detectar mudanças em arquivos no Docker (eventos nativos não propagam com volume mount)
  config.file_watcher = ActiveSupport::FileUpdateChecker
  config.consider_all_requests_local = true
  config.server_timing = true

  # Desabilita cache para que alterações em views sejam detectadas no Docker (volume mounts podem não propagar mtime)
  config.action_controller.perform_caching = false
  config.action_view.cache_template_loading = false

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # E-mail (SendGrid) — senha/API key via ENV, nunca no código.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.smtp_settings = {
    user_name: "apikey",
    password: ENV["SENDGRID_API_KEY"],
    domain: "swind.com.br",
    address: "smtp.sendgrid.net",
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Local por padrão; com ACTIVE_STORAGE_SERVICE=digitalocean_spaces no .env usa o bucket (docker-compose).
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym
  config.active_job.queue_adapter = :async
  config.action_cable.disable_request_forgery_protection = true

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
end
