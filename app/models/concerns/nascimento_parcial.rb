# frozen_string_literal: true

# Data de nascimento onde dia e mês são obrigatórios e o ano é opcional.
# O ano, mesmo informado, só é divulgado quando exibir_ano_nascimento for true.
module NascimentoParcial
  extend ActiveSupport::Concern

  ANO_MINIMO = 1900

  included do
    validates :nascimento_dia, inclusion: { in: 1..31, message: "deve estar entre 1 e 31" }, allow_nil: true
    validates :nascimento_mes, inclusion: { in: 1..12, message: "deve estar entre 1 e 12" }, allow_nil: true
    validates :nascimento_ano, numericality: { only_integer: true, greater_than_or_equal_to: ANO_MINIMO },
                               allow_nil: true
    validate :nascimento_ano_nao_futuro
    validate :nascimento_dia_existe_no_mes
  end

  def nascimento_informado?
    nascimento_dia.present? && nascimento_mes.present?
  end

  # "15/03" ou, se o ministro autorizou, "15/03/1950". Sem dados: nil.
  def nascimento_para_exibicao
    return unless nascimento_informado?

    base = format("%02d/%02d", nascimento_dia, nascimento_mes)
    ano_divulgavel? ? "#{base}/#{nascimento_ano}" : base
  end

  # Versão completa, apenas para a coordenação (admin).
  def nascimento_completo
    return unless nascimento_informado?

    base = format("%02d/%02d", nascimento_dia, nascimento_mes)
    nascimento_ano.present? ? "#{base}/#{nascimento_ano}" : base
  end

  def ano_divulgavel?
    exibir_ano_nascimento? && nascimento_ano.present?
  end

  def aniversario_hoje?(hoje = Date.current)
    nascimento_informado? && nascimento_dia == hoje.day && nascimento_mes == hoje.month
  end

  private

  def nascimento_ano_nao_futuro
    return if nascimento_ano.blank?

    errors.add(:nascimento_ano, "não pode ser no futuro") if nascimento_ano > Date.current.year
  end

  def nascimento_dia_existe_no_mes
    return unless nascimento_informado? && (1..12).cover?(nascimento_mes) && (1..31).cover?(nascimento_dia)

    # Usa ano bissexto quando o ano não é informado, para aceitar 29/02.
    ano = nascimento_ano.presence || 2000
    return if Date.valid_date?(ano, nascimento_mes, nascimento_dia)

    errors.add(:nascimento_dia, "não existe neste mês")
  end
end
