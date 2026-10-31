# frozen_string_literal: true

module Liturgia
  # Avisos de layout (não bloqueia export na v2 inicial; exibidos na preview admin).
  class CartazV2LayoutValidator
    def self.validate(liturgia, cartaz)
      new(liturgia, cartaz).warnings
    end

    def initialize(liturgia, cartaz)
      @liturgia = liturgia
      @cartaz = cartaz
    end

    def warnings
      w = []
      w << "Imagem do santo ausente." unless @liturgia.imagem_santo.attached?
      if @liturgia.imagem_santo.attached? && @liturgia.imagem_santo.byte_size < 25_000
        w << "Imagem do santo com resolução/tamanho baixo — pode pixelizar no cartaz."
      end
      w << "IGMR n.º #{@cartaz.igmr_numero} não cadastrado." if @cartaz.igmr_ausente?
      w << "Nenhuma celebração na escala para este dia." if @cartaz.linhas_escala.empty?
      w << "Nome do santo não informado." if @liturgia.santo_nome.blank?

      @cartaz.linhas_escala.each do |linha|
        if linha.ministros_celula.length > 48
          w << "Ministros (#{linha.horario}): nomes longos — confira legibilidade no PNG."
        end
      end

      igmr = @cartaz.igmr_paragrafo
      trecho = igmr&.texto_para_cartaz.to_s
      w << "Texto IGMR muito longo — cadastre um trecho_cartaz mais curto." if igmr && trecho.length > 520

      w
    end
  end
end
