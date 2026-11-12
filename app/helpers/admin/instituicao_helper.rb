# frozen_string_literal: true

module Admin
  module InstituicaoHelper
    MODULO_LABELS = {
      "escala_mesc" => "Escala MESC",
      "liturgia_cartaz" => "Liturgia e cartaz WhatsApp",
      "esportulas" => "Espórtulas",
      "financeiro_caixa" => "Financeiro / caixa",
      "escala_extra" => "Escala extra",
      "painel_sacerdote" => "Painel do sacerdote"
    }.freeze

    def instituicao_modulo_label(chave)
      MODULO_LABELS.fetch(chave.to_s, chave.to_s.humanize)
    end

    def instituicao_modulos_ativos(instituicao)
      Plano::RECURSOS_PADRAO.select { |chave| instituicao.recurso?(chave) }
    end

    def instituicao_tipo_label(tipo)
      case tipo.to_s
      when "comunidade" then "Comunidade"
      when "paroquia" then "Paróquia"
      else tipo.to_s.humanize
      end
    end

    def instituicao_url_publica(instituicao)
      base = ENV.fetch("INSTITUICAO_BASE_DOMAIN", "sacristia-digital.net.br")
      "https://#{instituicao.slug}.#{base}"
    end
  end
end
