# frozen_string_literal: true

class Ministro < ApplicationRecord
  include NascimentoParcial

  has_one :user, dependent: :nullify
  has_many :plantao_periodo_ministros, dependent: :destroy
  has_many :plantao_periodos, through: :plantao_periodo_ministros
  has_many :escala_ministros, dependent: :destroy
  has_many :escala_ministros_originais, class_name: "EscalaMinistro", foreign_key: :ministro_original_id,
                                        inverse_of: :ministro_original, dependent: :nullify
  has_many :evento_escalas, through: :escala_ministros
  has_many :oferta_apoios, dependent: :destroy

  SEXOS = %w[Masculino Feminino].freeze

  validates :nome, presence: true
  # validates :email, presence: true, uniqueness: true
  validates :sexo, inclusion: { in: SEXOS }, allow_blank: true
  # Dia e mês obrigatórios em novos cadastros (e se forem alterados), sem travar
  # a edição de ministros antigos que ainda não informaram.
  validates :nascimento_dia, :nascimento_mes, presence: true,
                                              if: -> { new_record? || nascimento_dia_changed? || nascimento_mes_changed? }

  scope :ativos, -> { where(ativo: true) }
  scope :aniversariantes_do_mes, ->(mes = Date.current.month) { where(nascimento_mes: mes).order(:nascimento_dia, :nome) }
  scope :ordenados_por_nome, -> { order(:nome) }

  def ativo?
    ativo
  end
end
