# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  # App Platform (container): logs em STDOUT para aparecerem em "Runtime Logs".
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").to_sym
  config.log_tags = [:request_id]
  config.eager_load = true
  config.consider_all_requests_local = false
  # DigitalOcean App Platform / container único: servir public/assets após precompile.
  # Defina RAILS_SERVE_STATIC_FILES=false se um proxy/CDN servir estáticos.
  config.public_file_server.enabled = ActiveModel::Type::Boolean.new.cast(
    ENV.fetch("RAILS_SERVE_STATIC_FILES", "true")
  )
  config.action_controller.perform_caching = true
  # Container único no App Platform: cache em memória. O solid_cache_store exigiria a tabela
  # solid_cache_entries e um banco de cache configurado em database.yml (não existem aqui);
  # sem isso o rate_limit do pré-cadastro e o cache da liturgia dão erro 500.
  config.cache_store = :memory_store, { size: 32.megabytes }

  # Imagens (ex.: santo do dia). Disco local: monte um volume persistente em /app/storage
  # ou troque por S3/Spaces em config/storage.yml.
  config.active_storage.service = :local
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "localhost") }
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.action_dispatch.default_headers = { "X-Frame-Options" => "SAMEORIGIN" }

  # Hosts: ver config/initializers/allowed_hosts.rb (APP_HOST, ALLOWED_HOSTS, after_initialize).
  config.hosts << "sacristia-digital-app-2df7e.ondigitalocean.app"
  config.hosts << "facedecristo.sacristia-digital.net.br"
end
