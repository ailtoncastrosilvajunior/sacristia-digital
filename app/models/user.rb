# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  belongs_to :ministro, optional: true

  PERFIS = %w[admin coordenador ministro].freeze

  validates :perfil, inclusion: { in: PERFIS }
  validates :nome, presence: true, if: -> { admin? || coordenador? }

  scope :admins, -> { where(perfil: "admin") }
  scope :coordenadores, -> { where(perfil: "coordenador") }
  scope :ministros, -> { where(perfil: "ministro") }

  def admin?
    perfil == "admin"
  end

  def coordenador?
    perfil == "coordenador"
  end

  def ministro?
    perfil == "ministro"
  end

  def pode_gerenciar_tudo?
    admin?
  end

  def pode_gerenciar_escalas?
    admin? || coordenador?
  end

  def pode_ver_propria_agenda?
    true
  end

  # Acesso à área "Minha escala" (dashboard ministro)
  def pode_acessar_dashboard_ministro?
    return true if ministro?
    return true if ministro.present? && (admin? || coordenador?)

    false
  end
end
