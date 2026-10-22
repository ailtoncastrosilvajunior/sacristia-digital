# frozen_string_literal: true

# Bloco de dias de plantão (escala extra) de uma competência, com seus ministros.
class PlantaoPeriodo < ApplicationRecord
  belongs_to :competencia_mensal
  has_many :plantao_periodo_ministros, -> { order(:ordem, :id) }, dependent: :destroy, inverse_of: :plantao_periodo
  has_many :ministros, through: :plantao_periodo_ministros
  has_many :evento_escalas, dependent: :nullify

  validates :dia_inicio, presence: true, numericality: { only_integer: true, in: 1..31 }
  validates :dia_fim, presence: true, numericality: { only_integer: true, in: 1..31 }
  validate :dia_fim_maior_ou_igual_dia_inicio
  validate :dentro_do_mes
  validate :sem_sobreposicao

  scope :ordenados, -> { order(:dia_inicio, :dia_fim) }

  def range_dias
    (dia_inicio..dia_fim).to_a
  end

  def cobre_dia?(dia)
    d = dia.respond_to?(:day) ? dia.day : dia
    return false if dia_inicio.blank? || dia_fim.blank?
    (dia_inicio..dia_fim).cover?(d)
  end

  def rotulo
    return "Dia #{dia_inicio}" if dia_inicio == dia_fim
    "Dias #{format('%02d', dia_inicio)} a #{format('%02d', dia_fim)}"
  end

  def nomes_ministros
    ministros.map(&:nome).join(" | ")
  end

  # Algum dia do bloco cai dentro do intervalo de datas (ex.: mês/semana visível na agenda).
  def sobrepoe_periodo?(periodo)
    return false if periodo.blank?

    range_dias.any? do |dia|
      data = Date.new(competencia_mensal.ano, competencia_mensal.mes, dia)
      periodo.cover?(data)
    rescue ArgumentError
      false
    end
  end

  # Copia o bloco (dias + ministros) para outra competência.
  def copiar_para!(competencia)
    novo = competencia.plantao_periodos.create!(dia_inicio: dia_inicio, dia_fim: dia_fim)
    plantao_periodo_ministros.each do |ppm|
      novo.plantao_periodo_ministros.create!(ministro_id: ppm.ministro_id, ordem: ppm.ordem)
    end
    novo
  end

  private

  def dia_fim_maior_ou_igual_dia_inicio
    return if dia_fim.blank? || dia_inicio.blank?
    errors.add(:dia_fim, "deve ser maior ou igual ao dia inicial") if dia_fim < dia_inicio
  end

  def dentro_do_mes
    return if competencia_mensal.blank? || dia_fim.blank?
    ultimo = competencia_mensal.periodo_fim.day
    errors.add(:dia_fim, "não pode ser maior que #{ultimo} (último dia do mês)") if dia_fim > ultimo
  end

  def sem_sobreposicao
    return if competencia_mensal_id.blank? || dia_inicio.blank? || dia_fim.blank?
    conflito = PlantaoPeriodo.where(competencia_mensal_id: competencia_mensal_id)
                             .where.not(id: id)
                             .where("dia_inicio <= ? AND dia_fim >= ?", dia_fim, dia_inicio)
                             .first
    errors.add(:base, "Os dias se sobrepõem ao bloco #{conflito.rotulo}") if conflito
  end
end
