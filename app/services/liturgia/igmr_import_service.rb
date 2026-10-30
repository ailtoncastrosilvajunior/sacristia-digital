# frozen_string_literal: true

require "csv"

module Liturgia
  # Importa parágrafos IGMR de CSV (numero + texto oficial). Upsert por número.
  class IgmrImportService
    Resultado = Struct.new(:criados, :atualizados, :ignorados, :erros, keyword_init: true) do
      def ok?
        erros.empty?
      end

      def resumo
        parts = []
        parts << "#{criados} criado(s)" if criados.positive?
        parts << "#{atualizados} atualizado(s)" if atualizados.positive?
        parts << "#{ignorados} linha(s) ignorada(s)" if ignorados.positive?
        parts << "#{erros.size} erro(s)" if erros.any?
        parts.presence&.join(", ") || "Nenhuma alteração"
      end
    end

    def self.call(io, atualizar_existentes: true)
      new(atualizar_existentes: atualizar_existentes).call(io)
    end

    def initialize(atualizar_existentes: true)
      @atualizar = atualizar_existentes
      @criados = 0
      @atualizados = 0
      @ignorados = 0
      @erros = []
    end

    def call(io)
      conteudo = io.read
      sep = conteudo.count(";") >= conteudo.count(",") ? ";" : ","
      linhas = CSV.parse(conteudo, col_sep: sep, headers: true, liberal_parsing: true)
      linhas.each_with_index do |row, idx|
        importar_linha(row, idx + 2)
      end
      Resultado.new(criados: @criados, atualizados: @atualizados, ignorados: @ignorados, erros: @erros)
    rescue CSV::MalformedCSVError => e
      Resultado.new(criados: 0, atualizados: 0, ignorados: 0, erros: ["CSV inválido: #{e.message}"])
    end

    private

    def importar_linha(row, linha_planilha)
      attrs = normalizar_row(row)
      if attrs[:numero].blank? || attrs[:texto].blank?
        @ignorados += 1
        return
      end
      if attrs[:numero] < 1 || attrs[:numero] > IgmrParagrafo::LIMITE_ROTACAO
        @erros << "Linha #{linha_planilha}: número #{attrs[:numero]} fora do intervalo 1–#{IgmrParagrafo::LIMITE_ROTACAO}."
        return
      end

      reg = IgmrParagrafo.find_by(numero: attrs[:numero])
      if reg && !@atualizar
        @ignorados += 1
        return
      end

      reg ||= IgmrParagrafo.new(numero: attrs[:numero])
      reg.assign_attributes(texto: attrs[:texto], fonte: attrs[:fonte], texto_conferido: attrs[:texto_conferido])
      if reg.new_record?
        reg.save ? @criados += 1 : registrar_erro(linha_planilha, reg)
      elsif reg.changed?
        reg.save ? @atualizados += 1 : registrar_erro(linha_planilha, reg)
      else
        @ignorados += 1
      end
    end

    def normalizar_row(row)
      h = row.to_h.transform_keys { |k| k.to_s.downcase.strip.gsub(/\s+/, "_") }
      numero = h["numero"].to_s.strip.presence || h["n"].to_s.strip.presence
      texto = h["texto"].to_s.strip.presence || h["paragrafo"].to_s.strip.presence
      fonte = h["fonte"].to_s.strip.presence
      conferido = parse_bool(h["texto_conferido"] || h["conferido"])
      {
        numero: numero&.to_i,
        texto: texto,
        fonte: fonte,
        texto_conferido: conferido
      }
    end

    def parse_bool(val)
      return false if val.blank?

      val.to_s.strip.downcase.in?(%w[1 true sim yes s])
    end

    def registrar_erro(linha, reg)
      @erros << "Linha #{linha}: #{reg.errors.full_messages.join(', ')}"
    end
  end
end
