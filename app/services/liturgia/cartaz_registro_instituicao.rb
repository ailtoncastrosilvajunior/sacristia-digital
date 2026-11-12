# frozen_string_literal: true

module Liturgia
  # Um registro de cartaz gerado (PNG) por instituição × dia litúrgico global.
  class CartazRegistroInstituicao
    class InstituicaoAusente < StandardError; end

    def self.for!(liturgia_dia)
      inst = Current.instituicao
      raise InstituicaoAusente, "Instituição não definida na requisição" unless inst

      LiturgiaCartaz.find_or_create_by!(instituicao_id: inst.id, liturgia_dia_id: liturgia_dia.id)
    end
  end
end
