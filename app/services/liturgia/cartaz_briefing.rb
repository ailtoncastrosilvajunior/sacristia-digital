# frozen_string_literal: true

module Liturgia
  # Texto pronto para colar no prompt do ChatGPT (dados validados do app).
  class CartazBriefing
    def self.text(liturgia_dia)
      new(liturgia_dia).to_s
    end

    def initialize(liturgia_dia)
      @ld = liturgia_dia
      @cartaz = CartazBuilder.build(liturgia_dia)
    end

    def to_s
      linhas = []
      linhas << "Use estes dados literais no cartaz MESC (não invente nem altere nomes, horários, referências ou texto da IGMR):"
      linhas << ""
      linhas << "DATA: #{I18n.l(@ld.data, format: '%d/%m/%Y')}"
      linhas << "DIA DA SEMANA: #{I18n.l(@ld.data, format: '%A').upcase}"
      linhas << "TEMPO / CELEBRAÇÃO: #{@ld.titulo.presence || '—'}"
      linhas << "COR LITÚRGICA: #{@ld.cor.presence || '—'}"
      linhas << "SANTO DO DIA: #{@ld.santo_nome.presence || '—'}"
      linhas << "SOBRE O SANTO: #{@ld.santo_descricao.presence || '—'}"
      linhas << ""
      linhas << "LITURGIA DA PALAVRA (somente referências — sem transcrever textos no cartaz)"
      @cartaz.linhas_leitura.each do |l|
        rotulo = l.rotulo == "Responsório" ? "Salmo responsorial" : l.rotulo
        linhas << "#{rotulo}: #{l.referencia}"
      end
      linhas << ""
      igmr = @cartaz.igmr_paragrafo
      linhas << "FORMAÇÃO MESC | IGMR"
      if igmr
        linhas << "IGMR, n. #{igmr.numero} (trecho — use literalmente, sem reescrever)"
        linhas << "Fonte: #{igmr.rotulo_edicao}"
        linhas << igmr.texto_para_cartaz
      else
        linhas << "IGMR n. #{@cartaz.igmr_numero} — cadastrar no app"
      end
      linhas << ""
      linhas << "ESCALA DOS MESC (uma linha por celebração; ministros separados por |)"
      if @cartaz.linhas_escala.any?
        @cartaz.linhas_escala.each do |ev|
          linhas << "#{ev.horario} | #{ev.presidente} | #{ev.ministros_celula}"
        end
      else
        linhas << "— Nenhuma celebração na escala deste dia —"
      end
      linhas << ""
      linhas << "Rodapé fixo: FACE DE CRISTO RESPLANDECEI EM NÓS"
      linhas.join("\n")
    end
  end
end
