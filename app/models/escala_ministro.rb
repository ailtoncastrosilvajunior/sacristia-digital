# frozen_string_literal: true

class EscalaMinistro < ApplicationRecord
  belongs_to :evento_escala
  belongs_to :ministro
  # Quem estava previsto quando houve substituição (nulo = sem troca).
  belongs_to :ministro_original, class_name: "Ministro", optional: true, inverse_of: :escala_ministros_originais

  has_many :solicitacao_trocas, dependent: :destroy

  validates :ministro_id, uniqueness: { scope: :evento_escala_id }

  scope :confirmados, -> { where(confirmado: true) }
  scope :coordenador, -> { where(coordenador: true) }
  scope :adoracao, -> { where(adoracao: true) }

  def confirmar!
    update!(confirmado: true, confirmado_em: Time.current)
  end

  def substituido?
    ministro_original_id.present?
  end

  # Substitui quem serve, preservando o primeiro previsto (trocas em cadeia).
  # Se quem assume for o próprio previsto, a troca é desfeita.
  def trocar_por!(novo_ministro, motivo: nil)
    original_id = ministro_original_id || ministro_id
    if novo_ministro.id == original_id
      update!(ministro: novo_ministro, ministro_original_id: nil, motivo_troca: nil, confirmado: false, confirmado_em: nil)
    else
      update!(ministro: novo_ministro, ministro_original_id: original_id, motivo_troca: motivo.presence,
              confirmado: false, confirmado_em: nil)
    end
  end
end
