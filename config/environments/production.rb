# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.action_controller.perform_caching = true
  config.cache_store = :solid_cache_store
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "localhost") }
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.action_dispatch.default_headers = { "X-Frame-Options" => "SAMEORIGIN" }

  config.hosts << "sacristia-digital-app-2df7e.ondigitalocean.app"
end
