# frozen_string_literal: true

class PlantaoPeriodo < ApplicationRecord
  belongs_to :competencia_mensal
  belongs_to :equipe

  validates :dia_inicio, presence: true, numericality: { in: 1..31 }
  validates :dia_fim, presence: true, numericality: { in: 1..31 }
  validate :dia_fim_maior_ou_igual_dia_inicio

  def dia_fim_maior_ou_igual_dia_inicio
    return if dia_fim.blank? || dia_inicio.blank?
    errors.add(:dia_fim, "deve ser maior ou igual ao dia inicial") if dia_fim < dia_inicio
  end

  def range_dias
    (dia_inicio..dia_fim).to_a
  end

  def cobre_dia?(dia)
    range_dias.include?(dia)
  end
end
