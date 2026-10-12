# frozen_string_literal: true

class LiturgiaSincronizarJob < ApplicationJob
  queue_as :default

  def perform(inicio = Date.current, dias = 14)
    inicio = inicio.to_date
    dias.times do |i|
      Liturgia::SincronizarService.call(inicio + i)
      sleep 0.3
    end
  end
end
