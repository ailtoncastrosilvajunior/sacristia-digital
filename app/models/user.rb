# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  belongs_to :ministro, optional: true
  belongs_to :sacerdote, optional: true

  PERFIS_VALIDOS = %w[admin coordenador ministro sacerdote].freeze

  before_validation :normalizar_perfis
  before_validation :sincronizar_vinculos_perfis

  validate :perfis_devem_ser_validos
  validate :pelo_menos_um_perfil
  validates :nome, presence: true, if: -> { admin? || coordenador? }
  validates :ministro, presence: true, if: -> { ministro? }
  validates :sacerdote, presence: true, if: -> { sacerdote? }

  scope :com_perfil, ->(p) { where("perfis @> ARRAY[?]::varchar[]", [p]) }
  scope :admins, -> { com_perfil("admin") }
  scope :coordenadores, -> { com_perfil("coordenador") }
  scope :ministros, -> { com_perfil("ministro") }

  def admin?
    perfis.include?("admin")
  end

  def coordenador?
    perfis.include?("coordenador")
  end

  def ministro?
    perfis.include?("ministro")
  end

  def sacerdote?
    perfis.include?("sacerdote")
  end

  def perfis_labels
    perfis.map { |p| I18n.t("activerecord.attributes.user.perfis_labels.#{p}", default: p.humanize) }
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

  def pode_acessar_dashboard_ministro?
    return true if ministro?
    return true if ministro.present? && (admin? || coordenador?)

    false
  end

  def perfil_principal_redirect
    return :admin if admin?
    return :coordenador if coordenador?
    return :ministro if pode_acessar_dashboard_ministro?
    return :sacerdote if sacerdote?

    :admin
  end

  private

  def normalizar_perfis
    self.perfis = Array(perfis).map(&:to_s).map(&:strip).reject(&:blank?).uniq.sort
  end

  def sincronizar_vinculos_perfis
    self.ministro_id = nil unless ministro? || admin? || coordenador?
    self.sacerdote_id = nil unless sacerdote?
  end

  def perfis_devem_ser_validos
    invalidos = perfis - PERFIS_VALIDOS
    errors.add(:base, "Perfis inválidos: #{invalidos.join(', ')}") if invalidos.any?
  end

  def pelo_menos_um_perfil
    errors.add(:perfis, :blank) if perfis.blank?
  end
end
