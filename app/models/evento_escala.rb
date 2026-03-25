# frozen_string_literal: true

class EventoEscala < ApplicationRecord
  self.table_name = "evento_escala"

  belongs_to :competencia_mensal
  belongs_to :tipo_servico
  belongs_to :sacerdote, optional: true
  belongs_to :equipe, optional: true

  has_many :escala_ministros, dependent: :destroy
  has_many :ministros, through: :escala_ministros
  has_one :escala_ministro_coordenador, -> { where(coordenador: true) }, class_name: "EscalaMinistro"
  has_one :ministro_coordenador, through: :escala_ministro_coordenador, source: :ministro
  has_one :escala_ministro_adoracao, -> { where(adoracao: true) }, class_name: "EscalaMinistro"
  has_one :ministro_adoracao, through: :escala_ministro_adoracao, source: :ministro
  has_many :registro_esportulas, dependent: :destroy

  TIPOS_ESCALA = %w[ordinaria extra].freeze
  STATUS = %w[pendente confirmado concluido cancelado].freeze

  validates :data, presence: true
  validates :horario, presence: true
  validates :quantidade_ministros, numericality: { greater_than_or_equal_to: 0 }
  validates :tipo_escala, inclusion: { in: TIPOS_ESCALA }
  validates :status, inclusion: { in: STATUS }

  scope :ordinarios, -> { where(tipo_escala: "ordinaria") }
  scope :extras, -> { where(tipo_escala: "extra") }
  scope :por_data, -> { order(:data, :horario) }
  scope :nao_cancelados, -> { where.not(status: "cancelado") }

  def data_hora
    return nil unless data && horario
    Time.zone.parse("#{data} #{horario}")
  end

  def ordinario?
    tipo_escala == "ordinaria"
  end

  def extra?
    tipo_escala == "extra"
  end

  def cancelado?
    status == "cancelado"
  end

  def to_s
    "#{tipo_servico.nome} - #{I18n.l(data)}"
  end

  def ministros_nomes_com_coordenador
    ems = escala_ministros.select { |em| em.ministro.present? }
    return "—" if ems.empty?
    ems.sort_by { |em| em.ministro.nome.to_s.downcase }.map do |em|
      parts = [em.ministro.nome]
      parts << "· coordenador" if em.coordenador?
      parts << "· adoração" if em.adoracao?
      parts.join(" ")
    end.join(", ")
  end
end
