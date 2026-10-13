# frozen_string_literal: true

class LiturgiaSincronizarJob < ApplicationJob
  queue_as :default

  def perform(inicio = Date.current, dias = 14)
    inicio = inicio.to_date
    Rails.logger.info("[Liturgia] Busca iniciada: #{inicio} (#{dias} dias)")
    dias.times do |i|
      data = inicio + i
      resposta = Liturgia::SincronizarService.call(data)
      if resposta.ok?
        Rails.logger.info("[Liturgia] #{data}: #{resposta.status}")
      else
        Rails.logger.warn("[Liturgia] #{data}: FALHOU - #{resposta.mensagem}")
      end
    rescue StandardError => e
      Rails.logger.error("[Liturgia] #{data}: erro inesperado - #{e.class}: #{e.message}")
    ensure
      sleep 0.3
    end
    Rails.logger.info("[Liturgia] Busca finalizada")
  end
end
