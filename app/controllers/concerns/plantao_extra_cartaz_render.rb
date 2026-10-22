# frozen_string_literal: true

# Página HTML do cartaz WhatsApp (plantão extra + eventos do período).
module PlantaoExtraCartazRender
  extend ActiveSupport::Concern

  def render_plantao_extra_cartaz
    @plantao = plantao_periodo_for_cartaz
    @competencia = @plantao.competencia_mensal
    @cartaz = PlantaoExtraCartaz.build(@plantao)
    render "plantao_extra/cartaz", layout: "cartaz_whatsapp"
  end

  private

  def plantao_periodo_for_cartaz
    raise NotImplementedError
  end
end
