# frozen_string_literal: true

module Liturgia
  class CartazBuilder
    LinhaEscala = Struct.new(:horario, :presidente, :ministros, keyword_init: true)
    LinhaLeitura = Struct.new(:rotulo, :referencia, :trecho, keyword_init: true)

    attr_reader :liturgia, :igmr, :eventos, :linhas_escala, :linhas_leitura

    def self.build(liturgia)
      new(liturgia).tap(&:load!)
    end

    def initialize(liturgia)
      @liturgia = liturgia
      @igmr = IgmrRotacao.new(liturgia.data)
      @eventos = []
      @linhas_escala = []
      @linhas_leitura = []
    end

    def load!
      @eventos = eventos_do_dia
      @linhas_escala = @eventos.map { |ev| linha_escala(ev) }
      @linhas_leitura = leituras_para_cartaz
    end

    def igmr_numero
      @igmr.numero
    end

    def igmr_paragrafo
      @igmr.paragrafo
    end

    def igmr_ausente?
      igmr_paragrafo.nil?
    end

    private

    def eventos_do_dia
      comp = CompetenciaMensal.find_by(ano: liturgia.data.year, mes: liturgia.data.month)
      return [] unless comp

      comp.evento_escalas
          .nao_cancelados
          .where(data: liturgia.data)
          .includes(:sacerdote, :tipo_servico, escala_ministros: :ministro)
          .order(:horario)
          .select(&:requer_ministros?)
    end

    def linha_escala(evento)
      horario = evento.horario.respond_to?(:strftime) ? evento.horario.strftime("%H:%M") : evento.horario.to_s[0, 5]
      presidente = evento.sacerdote&.nome.presence || "—"
      ministros = evento.escala_ministros
                        .select { |em| em.ministro.present? }
                        .sort_by { |em| em.ministro.nome.to_s.downcase }
                        .map { |em| rotulo_ministro(em) }
      ministros = ["—"] if ministros.empty?

      LinhaEscala.new(horario: horario, presidente: presidente, ministros: ministros)
    end

    def rotulo_ministro(em)
      nome = em.ministro.nome.to_s.split.first.presence || em.ministro.nome
      em.adoracao? ? "#{nome} (Adoração)" : nome
    end

    def leituras_para_cartaz
      mapa = liturgia.leituras_ordenadas.index_by { |l| l["tipo"] }
      tipos = %w[primeira_leitura salmo segunda_leitura evangelho]
      tipos.filter_map do |tipo|
        lei = mapa[tipo]
        next if lei.blank?

        rotulo = case tipo
                 when "salmo" then "Responsório"
                 when "primeira_leitura" then "1ª Leitura"
                 when "segunda_leitura" then "2ª Leitura"
                 else "Evangelho"
                 end
        LinhaLeitura.new(
          rotulo: rotulo,
          referencia: lei["referencia"].to_s,
          trecho: trecho(lei["texto"])
        )
      end
    end

    def trecho(texto, max: 95)
      t = texto.to_s.gsub(/\s+/, " ").strip
      return "—" if t.blank?

      t.length > max ? "#{t[0, max].strip}…" : t
    end
  end
end
