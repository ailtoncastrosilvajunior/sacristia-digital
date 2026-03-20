# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

# Carrega o ORM do Devise antes dos models (necessário para o método devise)
require "devise/orm/active_record"

# Fix PostgreSQL array_position(int2vector) - carrega após ActiveRecord
require_relative "initializers/postgresql_int2vector_compat"

module SacristiaDigital
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.generators do |g|
      g.orm :active_record
      g.template_engine :erb
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [:"pt-BR", :en]
    config.time_zone = "Brasilia"
  end
end
