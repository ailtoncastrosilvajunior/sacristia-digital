# frozen_string_literal: true

class CalendarioBase < ApplicationRecord
  self.table_name = "calendario_base"

  belongs_to :sacerdote, optional: true

  enum :tipo, { missa: "missa", confissao: "confissao" }, prefix: true

  validates :dia_da_semana, inclusion: { in: 0..6 }
  validates :quantidade_ministros, numericality: { greater_than_or_equal_to: 0 }

  scope :ativos, -> { where(ativo: true) }
  scope :por_dia, ->(dia) { where(dia_da_semana: dia) }

  def dia_nome
    I18n.l(Date.new(2024, 1, 7) + dia_da_semana, format: "%A")
  end
end
