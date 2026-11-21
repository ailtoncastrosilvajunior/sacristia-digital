# frozen_string_literal: true

module CentralHelper
  # Identidade fixa em tons de azul; a cor litúrgica do dia aparece em destaque como "paramentos".
  AZUL = { de: "#0c4a6e", ate: "#0284c7", destaque: "#bae6fd", claro: "#f0f9ff", forte: "#0369a1", texto: "#ffffff" }.freeze

  PARAMENTOS = {
    "verde" => "Verde", "roxa" => "Roxo", "branca" => "Branco", "vermelha" => "Vermelho", "rosa" => "Rosa", "preta" => "Preto"
  }.freeze

  # Cores da Central (fixas) + dados dos paramentos do dia (nome e cor real, de LiturgiaDia#cor_css).
  def tema_liturgico(liturgia)
    chave = liturgia&.cor.to_s.downcase
    chave = { "branco" => "branca", "vermelho" => "vermelha", "roxo" => "roxa", "preto" => "preta" }.fetch(chave, chave)
    AZUL.merge(nome: PARAMENTOS[chave], cor: liturgia&.cor_css)
  end

  def tema_css(tema)
    "--lit-de:#{tema[:de]};--lit-ate:#{tema[:ate]};--lit-destaque:#{tema[:destaque]};--lit-claro:#{tema[:claro]};--lit-forte:#{tema[:forte]};--lit-texto:#{tema[:texto]}"
  end

  # "hoje às 07:00", "amanhã às 12:10", "em 3 dias · sex, 04/12"
  def quando_servico(evento, hoje = Date.current)
    hora = l(evento.horario, format: :time)
    dias = (evento.data - hoje).to_i
    case dias
    when 0 then "Hoje às #{hora}"
    when 1 then "Amanhã às #{hora}"
    else "Em #{dias} dias · #{I18n.t('date.abbr_day_names')[evento.data.wday]}, #{l(evento.data, format: '%d/%m')} às #{hora}"
    end
  end
end
