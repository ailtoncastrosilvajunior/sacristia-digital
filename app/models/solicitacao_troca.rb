# frozen_string_literal: true

# Troca combinada entre ministros: quem serve indica o substituto, e só o substituto precisa aceitar.
# Ao aceitar, a escala é atualizada na hora (sem aprovação de admin ou coordenador).
class SolicitacaoTroca < ApplicationRecord
  STATUSES = %w[pendente aceita recusada cancelada].freeze

  belongs_to :escala_ministro
  belongs_to :substituto, class_name: "Ministro"

  validates :status, inclusion: { in: STATUSES }
  validates :motivo, length: { maximum: 500 }
  validate :substituto_valido, on: :create
  validate :uma_pendente_por_escala, on: :create

  scope :pendentes, -> { where(status: "pendente") }
  scope :recentes, -> { order(created_at: :desc) }

  delegate :evento_escala, to: :escala_ministro

  # Ministro que pediu para sair da celebração.
  def solicitante
    escala_ministro.ministro
  end

  def pendente?
    status == "pendente"
  end

  # Substituto aceita: assume a vaga e a escala é atualizada.
  def aceitar!
    return false unless pendente?

    aceita = false
    transaction do
      escala_ministro.reload
      if ainda_valida?
        escala_ministro.trocar_por!(substituto, motivo: motivo)
        update!(status: "aceita", respondido_em: Time.current)
        aceita = true
      end
    end
    aceita
  end

  def recusar!
    encerrar!("recusada")
  end

  def cancelar!
    encerrar!("cancelada")
  end

  private

  def encerrar!(novo_status)
    return false unless pendente?

    update!(status: novo_status, respondido_em: Time.current)
    true
  end

  # A vaga ainda é do solicitante, a celebração segue de pé e o substituto não entrou na equipe nesse meio-tempo.
  def ainda_valida?
    ev = escala_ministro.evento_escala
    !ev.cancelado? && ev.data >= Date.current &&
      !ev.escala_ministros.where(ministro_id: substituto_id).exists?
  end

  def substituto_valido
    return if substituto.blank? || escala_ministro.blank?

    ev = escala_ministro.evento_escala
    errors.add(:substituto, "não pode ser você mesmo") if substituto_id == escala_ministro.ministro_id
    errors.add(:substituto, "já está escalado nesta celebração") if ev.escala_ministros.exists?(ministro_id: substituto_id)
    errors.add(:substituto, "está inativo") unless substituto.ativo?
  end

  def uma_pendente_por_escala
    return unless self.class.pendentes.where(escala_ministro_id: escala_ministro_id).exists?

    errors.add(:base, "Já existe um pedido de troca pendente para esta celebração.")
  end
end
