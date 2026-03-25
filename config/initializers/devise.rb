# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "noreply@sacristiadigital.local"
  config.stretches = Rails.env.test? ? 1 : 12
  config.pepper = Rails.application.credentials.dig(:devise, :pepper) || "devise_pepper_placeholder_change_in_production"
  config.secret_key = Rails.application.credentials.dig(:devise, :secret_key) || "devise_secret_key_placeholder_change_in_production"
  config.confirm_within = 3.days
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  # Lista vazia faz o Devise não redirecionar após entrar/sair (resposta “não navegável”),
  # o que quebra logout com Turbo/HTML. Inclua :turbo_stream para formulários enviados pelo Turbo.
  config.navigational_formats = %i[html turbo_stream]
end
