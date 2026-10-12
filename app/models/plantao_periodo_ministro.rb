# frozen_string_literal: true

class PlantaoPeriodoMinistro < ApplicationRecord
  belongs_to :plantao_periodo, inverse_of: :plantao_periodo_ministros
  belongs_to :ministro

  validates :ministro_id, uniqueness: { scope: :plantao_periodo_id }
end
