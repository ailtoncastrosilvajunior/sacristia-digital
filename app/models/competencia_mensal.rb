# frozen_string_literal: true

class CompetenciaMensal < ApplicationRecord
  self.table_name = "competencia_mensal"

  has_many :evento_escalas, dependent: :destroy
  has_many :plantao_periodos, dependent: :destroy
  has_many :oferta_apoios, dependent: :destroy
  has_many :lote_pagamento_esportulas, dependent: :destroy

  validates :ano, presence: true, numericality: { in: 2020..2100 }
  validates :mes, presence: true, numericality: { in: 1..12 }
  validates :mes, uniqueness: { scope: :ano }

  scope :ordenados, -> { order(ano: :desc, mes: :desc) }
  scope :liberadas_para_ministros, -> { where(escala_liberada: true) }

  def periodo
    Date.new(ano, mes, 1)
  end

  def periodo_fim
    periodo.end_of_month
  end

  def label
    I18n.l(periodo, format: :month_year)
  end

  # Competência de mês futuro: pode estar liberada, mas ainda não está em vigor.
  def futura?(hoje = Date.current)
    periodo > hoje.beginning_of_month
  end

  def label_curto
    abbr = I18n.t("date.abbr_month_names")[mes]
    "#{abbr}/#{format('%02d', ano % 100)}"
  end

  # Bloco de plantão extra que cobre o dia (Date ou número do dia).
  def plantao_para_dia(dia)
    plantao_periodos.includes(:ministros).find { |pp| pp.cobre_dia?(dia) }
  end

  def competencia_anterior
    ref = periodo.prev_month
    self.class.find_by(ano: ref.year, mes: ref.month)
  end

  # Copia os blocos de plantão (dias + ministros) de outra competência.
  # Mesmos dias, mesmos ministros; blocos que excedem o mês são ajustados.
  def copiar_plantao_de!(origem)
    ultimo = periodo_fim.day
    transaction do
      origem.plantao_periodos.includes(:plantao_periodo_ministros).ordenados.each do |pp|
        next if pp.dia_inicio > ultimo
        novo = plantao_periodos.create!(dia_inicio: pp.dia_inicio, dia_fim: [pp.dia_fim, ultimo].min)
        pp.plantao_periodo_ministros.each do |ppm|
          novo.plantao_periodo_ministros.create!(ministro_id: ppm.ministro_id, ordem: ppm.ordem)
        end
      end
    end
  end

  def self.para_mes(ano, mes)
    find_or_create_by!(ano: ano, mes: mes)
  end
end
