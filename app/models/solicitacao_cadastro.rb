# frozen_string_literal: true

# Pré-cadastro público de ministro. Só vira Ministro + User após aprovação do admin.
class SolicitacaoCadastro < ApplicationRecord
  STATUSES = %w[pendente aprovada rejeitada].freeze
  SENHA_MINIMA = 8

  include NascimentoParcial

  belongs_to :ministro, optional: true
  belongs_to :avaliado_por, class_name: "User", optional: true

  attr_accessor :password, :password_confirmation, :email_confirmation

  before_validation :normalizar

  validates :nome_completo, presence: true, length: { maximum: 200 }
  validates :nome, presence: true, length: { maximum: 40 }
  validates :email, presence: true, format: { with: Devise.email_regexp }, length: { maximum: 200 }
  validates :email, confirmation: true, on: :create
  validates :email_confirmation, presence: true, on: :create
  validates :sexo, inclusion: { in: Ministro::SEXOS }, allow_blank: true
  validates :nascimento_dia, :nascimento_mes, presence: true, on: :create
  validates :status, inclusion: { in: STATUSES }
  validates :password, presence: true, length: { minimum: SENHA_MINIMA, maximum: 128 },
                       confirmation: true, on: :create
  validates :password_confirmation, presence: true, on: :create
  validate :email_disponivel, on: :create
  validate :ano_obrigatorio_se_autorizar_divulgacao, on: :create

  before_create :garantir_exibir_ano_coerente
  before_create :gerar_hash_senha

  scope :pendentes, -> { where(status: "pendente") }
  scope :recentes, -> { order(created_at: :desc) }

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  # Cria Ministro (ou atualiza um existente) e o User com a senha escolhida na solicitação.
  # Retorna true/false; em caso de falha os motivos ficam em +errors+.
  def aprovar!(admin, ministro_existente: nil)
    return false unless pendente?

    if ministro_existente&.user.present?
      errors.add(:base, "O ministro selecionado já possui usuário de acesso.")
      return false
    end

    transaction do
      ministro = ministro_existente || Ministro.new(ativo: true)
      ministro.assign_attributes(nome: nome, nome_completo: nome_completo, email: email, telefone: telefone.presence || ministro.telefone,
                                 sexo: sexo.presence || ministro.sexo,
                                 nascimento_dia: nascimento_dia, nascimento_mes: nascimento_mes,
                                 nascimento_ano: nascimento_ano.presence || ministro.nascimento_ano,
                                 exibir_ano_nascimento: nascimento_ano.present? ? exibir_ano_nascimento : ministro.exibir_ano_nascimento)
      ministro.save!

      user = User.new(email: email, nome: nome, perfis: %w[ministro], ministro: ministro,
                      password: SecureRandom.hex(24))
      user.save!
      # Substitui a senha aleatória pelo hash escolhido pelo ministro.
      user.update_columns(encrypted_password: encrypted_password)

      update!(status: "aprovada", ministro: ministro, avaliado_por: admin,
              avaliado_em: Time.current, encrypted_password: nil)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.record.errors.full_messages.to_sentence)
    false
  end

  def rejeitar!(admin, motivo: nil)
    return false unless pendente?

    update!(status: "rejeitada", motivo_rejeicao: motivo.presence, avaliado_por: admin,
            avaliado_em: Time.current, encrypted_password: nil)
  end

  private

  def normalizar
    self.nome = nome.to_s.squish
    self.nome_completo = nome_completo.to_s.squish
    self.email = email.to_s.strip.downcase
    self.email_confirmation = email_confirmation.to_s.strip.downcase if email_confirmation
    self.telefone = telefone.to_s.strip.presence
    self.sexo = sexo.presence
    descartar_ano_inconsistente_se_nao_divulgavel
  end

  # Pré-cadastro: quem não autoriza divulgar o ano não deve ser barrado por ano
  # inconsistente (autofill do celular, 29/02 em ano comum etc.) — guardamos só dia/mês.
  def descartar_ano_inconsistente_se_nao_divulgavel
    return if nascimento_ano.blank? || exibir_ano_nascimento?
    return unless nascimento_informado?
    return if Date.valid_date?(nascimento_ano, nascimento_mes, nascimento_dia)

    self.nascimento_ano = nil
  end

  def ano_obrigatorio_se_autorizar_divulgacao
    return unless exibir_ano_nascimento?
    return if nascimento_ano.present?

    errors.add(:nascimento_ano, "informe o ano ou desmarque a autorização de divulgação")
  end

  # Mensagem genérica de propósito: não revela se o e-mail já está cadastrado.
  def email_disponivel
    return if email.blank?

    em_uso = User.where("LOWER(email) = ?", email).exists? ||
             SolicitacaoCadastro.pendentes.where("LOWER(email) = ?", email).exists?
    return unless em_uso

    errors.add(:base, "Não foi possível registrar com este e-mail. Se você já tem cadastro, entre no sistema " \
                      "ou procure o coordenador.")
  end

  # Usa o mesmo algoritmo do Devise (inclui pepper/stretches configurados).
  def gerar_hash_senha
    self.encrypted_password = User.new(password: password).encrypted_password
  end

  def garantir_exibir_ano_coerente
    self.exibir_ano_nascimento = false if nascimento_ano.blank?
  end
end
