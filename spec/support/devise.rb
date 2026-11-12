# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :request

  config.before(:suite) do
    Rails.application.routes_reloader.execute_unless_loaded
  end

  config.before(:each, type: :request) do
    Rails.application.routes_reloader.execute_unless_loaded
    Warden.test_mode!
  end

  config.after(:each, type: :request) do
    Warden.test_reset!
  end
end
