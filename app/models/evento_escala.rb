# frozen_string_literal: true

class EventoEscala < ApplicationRecord
  self.table_name = "evento_escala"

  belongs_to :competencia_mensal
  belongs_to :tipo_servico
  belongs_to :sacerdote, optional: true
  belongs_to :plantao_periodo, optional: true
  belongs_to :calendario_base, optional: true
  belongs_to :esportula_destinatario_sacerdote, class_name: "Sacerdote", optional: true
  belongs_to :destinatario_esportula, class_name: "DestinatarioEsportula", optional: true

  ESPORTULA_MODOS = %w[imediato acumulado].freeze
  ESPORTULA_DESTINATARIO_TIPOS = %w[sacerdote instituicao].freeze

  has_many :escala_ministros, dependent: :destroy
  has_many :ministros, through: :escala_ministros
  has_one :escala_ministro_coordenador, -> { where(coordenador: true) }, class_name: "EscalaMinistro"
  has_one :ministro_coordenador, through: :escala_ministro_coordenador, source: :ministro
  has_one :escala_ministro_adoracao, -> { where(adoracao: true) }, class_name: "EscalaMinistro"
  has_one :ministro_adoracao, through: :escala_ministro_adoracao, source: :ministro
  has_many :registro_esportulas, dependent: :destroy
  has_many :lancamentos_caixa, dependent: :nullify
  has_one :lote_pagamento_esportula_evento, dependent: :destroy
  has_one :lote_pagamento_esportula, through: :lote_pagamento_esportula_evento

  TIPOS_ESCALA = %w[ordinaria extra].freeze
  STATUS = %w[pendente confirmado concluido cancelado].freeze

  validates :data, presence: true
  validates :horario, presence: true
  validates :quantidade_ministros, numericality: { greater_than_or_equal_to: 0 }
  validates :tipo_escala, inclusion: { in: TIPOS_ESCALA }
  validates :status, inclusion: { in: STATUS }
  validates :esportula_modo, inclusion: { in: ESPORTULA_MODOS }
  validates :esportula_destinatario_tipo, inclusion: { in: ESPORTULA_DESTINATARIO_TIPOS }
  validate :plantao_apenas_para_extra

  # Preenche a escala do evento com os ministros do bloco de plantão (cópia).
  def popular_escala_do_plantao!
    return unless plantao_periodo && escala_ministros.none?

    plantao_periodo.ministros.each do |ministro|
      escala_ministros.create!(ministro: ministro)
    end
  end

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

  def registro_esportula_vinculado
    registro_esportulas.first
  end

  def esportula_paga?
    registro_esportula_vinculado&.status == "pago"
  end

  def esportula_lancamento_caixa
    reg = registro_esportula_vinculado
    return nil unless reg&.status == "pago"

    if reg.lote_pagamento_esportula_id.present?
      reg.lote_pagamento_esportula&.lancamento_caixa
    else
      reg.lancamento_caixa
    end
  end

  def esportula_imediato?
    esportula_modo == "imediato"
  end

  def esportula_acumulado?
    esportula_modo == "acumulado"
  end

  def esportula_substituto_no_slot?
    return false if calendario_base_id.blank? || calendario_base.blank?

    calendario_base.sacerdote_id.present? && sacerdote_id != calendario_base.sacerdote_id
  end

  def esportula_destinatario_nome
    if esportula_destinatario_tipo == "instituicao"
      destinatario_esportula&.nome || "Instituição"
    else
      esportula_destinatario_sacerdote&.nome || sacerdote&.nome || "—"
    end
  end

  def esportula_pagamento_chave_destinatario
    if esportula_destinatario_tipo == "instituicao"
      ["instituicao", destinatario_esportula_id]
    else
      ["sacerdote", esportula_destinatario_sacerdote_id]
    end
  end

  # Eventos com 0 ministros (ex.: confissão) não entram na escala de ministros.
  def requer_ministros?
    quantidade_ministros.positive? || escala_ministros.any?
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

  private

  def plantao_apenas_para_extra
    return if plantao_periodo_id.blank?

    errors.add(:plantao_periodo_id, "só se aplica a eventos extras") unless extra?
    if plantao_periodo && plantao_periodo.competencia_mensal_id != competencia_mensal_id
      errors.add(:plantao_periodo_id, "deve pertencer à mesma competência do evento")
    end
  end
end
