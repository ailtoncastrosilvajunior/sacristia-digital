# frozen_string_literal: true

class EscalaMinistro < ApplicationRecord
  belongs_to :evento_escala
  belongs_to :ministro

  validates :ministro_id, uniqueness: { scope: :evento_escala_id }

  scope :confirmados, -> { where(confirmado: true) }

  def confirmar!
    update!(confirmado: true, confirmado_em: Time.current)
  end
end
