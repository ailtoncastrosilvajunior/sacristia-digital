# frozen_string_literal: true

module Liturgia
  # Itens visuais antes de liberar o briefing ChatGPT (cartaz WhatsApp).
  class BriefingChecklist
    include Rails.application.routes.url_helpers

    Item = Struct.new(:id, :label, :detail, :ok, :bloqueia, :action_path, :action_label, keyword_init: true)

    def initialize(liturgia_dia)
      @ld = liturgia_dia
      @cartaz = CartazBuilder.build(liturgia_dia, trecho_max: 280)
    end

    def items
      @items ||= montar_itens
    end

    def briefing_liberado?
      items.none? { |i| i.bloqueia && !i.ok }
    end

    def igmr_numero
      @cartaz.igmr_numero
    end

    def volta_liturgia_path(aba: "briefing")
      admin_liturgia_dia_path(@ld, aba: aba)
    end

    private

    def igmr_form_path(igmr, numero)
      volta = volta_liturgia_path
      if igmr
        edit_admin_igmr_paragrafo_path(igmr, return_to: volta)
      else
        new_admin_igmr_paragrafo_path(numero: numero, return_to: volta)
      end
    end

    def montar_itens
      n = @cartaz.igmr_numero
      igmr = @cartaz.igmr_paragrafo
      escala_qtd = @cartaz.linhas_escala.size

      [
        Item.new(
          id: :validada,
          label: "Liturgia validada",
          detail: "Visível para ministros",
          ok: @ld.validada?,
          bloqueia: false
        ),
        Item.new(
          id: :santo,
          label: "Santo do dia",
          detail: @ld.santo_nome.presence || "Informe na edição da liturgia",
          ok: @ld.santo_nome.present?,
          bloqueia: false
        ),
        Item.new(
          id: :leituras,
          label: "Leituras",
          detail: @ld.leituras.present? ? "1ª leitura, salmo e evangelho" : "Sincronize ou edite as leituras",
          ok: @ld.leituras.present?,
          bloqueia: false
        ),
        Item.new(
          id: :igmr,
          label: "IGMR do dia",
          detail: igmr ? "Parágrafo n.º #{n} cadastrado" : "Cadastre o parágrafo n.º #{n} (texto do cartaz)",
          ok: igmr.present?,
          bloqueia: true,
          action_path: igmr_form_path(igmr, n),
          action_label: igmr ? "Revisar texto" : "Cadastrar IGMR #{n}"
        ),
        Item.new(
          id: :escala,
          label: "Escala do dia",
          detail: escala_qtd.positive? ? "#{escala_qtd} celebração(ões) na competência" : "Nenhuma missa na escala — o briefing avisará",
          ok: escala_qtd.positive?,
          bloqueia: false
        ),
        Item.new(
          id: :foto_santo,
          label: "Foto do santo",
          detail: @ld.imagem_santo.attached? ? "Disponível para baixar no briefing" : "Opcional — busque de novo ou anexe na edição",
          ok: @ld.imagem_santo.attached?,
          bloqueia: false
        )
      ]
    end
  end
end
