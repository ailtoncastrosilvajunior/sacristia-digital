# frozen_string_literal: true

class DestinatarioEsportula < ApplicationRecord
  self.table_name = "destinatarios_esportula"

  has_many :calendario_base, dependent: :nullify
  has_many :evento_escalas, foreign_key: :destinatario_esportula_id, dependent: :nullify
  has_many :lote_pagamento_esportulas, dependent: :restrict_with_error

  validates :nome, presence: true

  scope :ativos, -> { where(ativo: true) }
  scope :ordenados, -> { order(:nome) }

  def to_s
    nome
  end
end
