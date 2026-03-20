# frozen_string_literal: true

class Ministro < ApplicationRecord
  has_one :user, dependent: :nullify
  has_many :equipe_ministros, dependent: :destroy
  has_many :equipes, through: :equipe_ministros
  has_many :escala_ministros, dependent: :destroy
  has_many :evento_escalas, through: :escala_ministros

  SEXOS = %w[Masculino Feminino].freeze

  validates :nome, presence: true
  validates :email, presence: true, uniqueness: true
  validates :sexo, inclusion: { in: SEXOS }, allow_blank: true

  scope :ativos, -> { where(ativo: true) }
  scope :ordenados_por_nome, -> { order(:nome) }

  def ativo?
    ativo
  end
end
