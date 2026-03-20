# frozen_string_literal: true

class Equipe < ApplicationRecord
  has_many :equipe_ministros, dependent: :destroy
  has_many :ministros, through: :equipe_ministros
  has_many :plantao_periodos, dependent: :destroy
  has_many :evento_escalas, dependent: :nullify

  validates :nome, presence: true
end
