# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.2.0"

gem "rails", "~> 8.0"
gem "propshaft"
gem "pg"
gem "puma", ">= 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
# Necessário em Windows e JRuby
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "bootsnap", require: false

# Autenticação
gem "devise", "~> 4.9"

# Formulários e UI
gem "simple_form", "~> 5.3"
gem "kaminari", "~> 1.2"

# Autorização
gem "pundit", "~> 2.3"

# Cache e filas (Rails 8 default)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduz boot times
gem "debug", platforms: %i[mri mingw mswin x64_mingw], group: %i[development test]

group :development do
  gem "web-console"
end

group :development, :test do
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
end
