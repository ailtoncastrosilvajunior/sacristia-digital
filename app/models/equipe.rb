# frozen_string_literal: true

class Equipe < ApplicationRecord
  has_many :equipe_ministros, dependent: :destroy
  has_many :ministros, through: :equipe_ministros
  has_many :plantao_periodos, dependent: :destroy
  has_many :evento_escalas, dependent: :nullify

  validates :nome, presence: true
  validates :dia_inicio, numericality: { in: 1..31, allow_nil: true }
  validates :dia_fim, numericality: { in: 1..31, allow_nil: true }
  validate :dia_fim_maior_ou_igual_dia_inicio, if: -> { dia_inicio.present? && dia_fim.present? }

  def self.para_dia(dia, competencia: nil)
    return nil unless dia.is_a?(Date) || dia.respond_to?(:day)
    d = dia.respond_to?(:day) ? dia.day : dia
    if competencia
      periodo = competencia.plantao_periodos.find { |pp| pp.cobre_dia?(d) }
      return periodo&.equipe
    end
    find_by("dia_inicio IS NOT NULL AND dia_fim IS NOT NULL AND ? BETWEEN dia_inicio AND dia_fim", d)
  end

  def cobre_dia?(dia)
    return false if dia_inicio.blank? || dia_fim.blank?
    d = dia.respond_to?(:day) ? dia.day : dia
    (dia_inicio..dia_fim).cover?(d)
  end

  private

  def dia_fim_maior_ou_igual_dia_inicio
    errors.add(:dia_fim, "deve ser maior ou igual ao dia inicial") if dia_fim < dia_inicio
  end
end
