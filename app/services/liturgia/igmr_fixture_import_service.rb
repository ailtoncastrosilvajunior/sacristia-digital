# frozen_string_literal: true

module Liturgia
  # Importa parágrafos IGMR do JSON gerado a partir do PDF CNBB (upsert por número).
  class IgmrFixtureImportService
    FIXTURE_PATH = Rails.root.join("db/fixtures/igmr_paragrafos_cnbb_2002.json")

    Resultado = Struct.new(:criados, :atualizados, :ignorados, keyword_init: true)

    def self.call(update_existing: true, preserve_conferidos: true)
      new(update_existing: update_existing, preserve_conferidos: preserve_conferidos).call
    end

    def initialize(update_existing: true, preserve_conferidos: true)
      @update_existing = update_existing
      @preserve_conferidos = preserve_conferidos
      @criados = 0
      @atualizados = 0
      @ignorados = 0
    end

    def call
      unless File.file?(FIXTURE_PATH)
        raise Errno::ENOENT, "Fixture não encontrado: #{FIXTURE_PATH}"
      end

      rows = JSON.parse(File.read(FIXTURE_PATH))
      conferidos = @preserve_conferidos ? IgmrParagrafo.where(texto_conferido: true).pluck(:numero).to_set : Set.new

      IgmrParagrafo.transaction do
        rows.each { |row| importar_row(row, conferidos) }
      end

      Resultado.new(criados: @criados, atualizados: @atualizados, ignorados: @ignorados)
    end

    private

    def importar_row(row, conferidos)
      numero = row["numero"].to_i
      texto = row["texto"].to_s.strip
      if numero < 1 || texto.blank?
        @ignorados += 1
        return
      end

      reg = IgmrParagrafo.find_or_initialize_by(numero: numero)
      if reg.persisted? && !@update_existing
        @ignorados += 1
        return
      end

      if reg.persisted? && conferidos.include?(numero)
        @ignorados += 1
        return
      end

      novo = reg.new_record?
      reg.assign_attributes(
        texto: texto,
        edicao: row["edicao"].presence || IgmrParagrafo::EDICAO_REFERENCIA,
        fonte: row["fonte"].presence || "db/fixtures/igmr_cnbb_2002.pdf"
      )

      if reg.changed?
        reg.save!
        novo ? @criados += 1 : @atualizados += 1
      else
        @ignorados += 1
      end
    end
  end
end
