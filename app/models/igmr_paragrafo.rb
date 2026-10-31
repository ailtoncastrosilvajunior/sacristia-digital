# frozen_string_literal: true

# Texto oficial dos parágrafos da IGMR para o cartaz diário (conferir com o livro impresso).
class IgmrParagrafo < ApplicationRecord
  # Último n.º da IGMR na edição de referência; ao passar disso a rotação recomeça do n.º 1.
  LIMITE_ROTACAO = 399
  # Padronize toda a base nesta edição (conferir com o livro físico CNBB).
  EDICAO_REFERENCIA = "IGMR — tradução oficial CNBB (Brasil)".freeze

  validates :numero, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :texto, presence: true

  scope :ordenados, -> { order(:numero) }

  def self.ultimo_numero_cadastrado
    maximum(:numero)
  end

  # Trecho curto para cartaz/briefing; parágrafo integral fica em `texto`.
  def texto_para_cartaz
    trecho_cartaz.presence || texto.to_s.strip
  end

  def rotulo_edicao
    edicao.presence || fonte.presence || EDICAO_REFERENCIA
  end
end
