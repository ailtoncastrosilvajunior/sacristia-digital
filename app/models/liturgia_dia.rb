# frozen_string_literal: true

class LiturgiaDia < ApplicationRecord
  self.table_name = "liturgia_dias"

  STATUSES = %w[rascunho validada].freeze
  CORES = %w[Verde Branca Vermelha Roxa Rosa Preta].freeze
  TIPOS_LEITURA = {
    "primeira_leitura" => "1ª Leitura",
    "salmo" => "Salmo",
    "segunda_leitura" => "2ª Leitura",
    "evangelho" => "Evangelho"
  }.freeze

  serialize :leituras, type: Array, coder: JSON
  serialize :leituras_conferencia, type: Array, coder: JSON
  serialize :divergencias, type: Array, coder: JSON

  has_one_attached :imagem_santo
  belongs_to :validado_por, class_name: "User", optional: true

  validates :data, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validate :imagem_valida

  scope :validadas, -> { where(status: "validada") }
  scope :rascunhos, -> { where(status: "rascunho") }
  scope :ordenados, -> { order(data: :desc) }

  def validada?
    status == "validada"
  end

  def rascunho?
    !validada?
  end

  def divergente?
    divergencias.present?
  end

  def validar!(user)
    update!(status: "validada", validado_por: user, validado_em: Time.current)
  end

  def reabrir!
    update!(status: "rascunho", validado_por: nil, validado_em: nil)
  end

  CAMPOS_CONTEUDO = %w[titulo cor santo_nome santo_descricao leituras].freeze

  # Qualquer edição de conteúdo exige nova validação antes de chegar ao ministro.
  def reabrir_status_se_alterado!
    return unless validada?
    return unless (changed & CAMPOS_CONTEUDO).any? || attachment_changes["imagem_santo"].present?

    self.status = "rascunho"
    self.validado_por = nil
    self.validado_em = nil
  end

  def leituras_ordenadas
    ordem = TIPOS_LEITURA.keys
    Array(leituras).sort_by { |l| ordem.index(l["tipo"]) || ordem.size }
  end

  def rotulo_leitura(leitura)
    TIPOS_LEITURA[leitura["tipo"]] || leitura["rotulo"].presence || leitura["tipo"].to_s.humanize
  end

  def cor_css
    case cor.to_s.downcase
    when "verde" then "#15803d"
    when "branca", "branco" then "#ffffff"
    when "vermelha", "vermelho" then "#b91c1c"
    when "roxa", "roxo" then "#6d28d9"
    when "rosa" then "#ec4899"
    when "preta", "preto" then "#292524"
    else "#a8a29e"
    end
  end

  # Texto legível sobre o fundo da cor litúrgica.
  def cor_texto_css
    cor.to_s.downcase.start_with?("branc") ? "#44403c" : "#ffffff"
  end

  private

  def imagem_valida
    return unless imagem_santo.attached?

    unless imagem_santo.content_type.to_s.start_with?("image/")
      errors.add(:imagem_santo, "deve ser uma imagem")
    end
    errors.add(:imagem_santo, "deve ter no máximo 5 MB") if imagem_santo.byte_size > 5.megabytes
  end
end
