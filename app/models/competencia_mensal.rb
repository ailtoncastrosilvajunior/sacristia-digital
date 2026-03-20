# frozen_string_literal: true

class CompetenciaMensal < ApplicationRecord
  self.table_name = "competencia_mensal"

  has_many :evento_escalas, dependent: :destroy
  has_many :plantao_periodos, dependent: :destroy

  validates :ano, presence: true, numericality: { in: 2020..2100 }
  validates :mes, presence: true, numericality: { in: 1..12 }
  validates :mes, uniqueness: { scope: :ano }

  scope :ordenados, -> { order(ano: :desc, mes: :desc) }

  def periodo
    Date.new(ano, mes, 1)
  end

  def periodo_fim
    periodo.end_of_month
  end

  def label
    I18n.l(periodo, format: :month_year)
  end

  def self.para_mes(ano, mes)
    find_or_create_by!(ano: ano, mes: mes)
  end
end
