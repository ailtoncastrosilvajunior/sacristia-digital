# frozen_string_literal: true

class ImportIgmrParagrafosCnbbFixture < ActiveRecord::Migration[7.2]
  def up
    return unless File.file?(Liturgia::IgmrFixtureImportService::FIXTURE_PATH)

    Liturgia::IgmrFixtureImportService.call(update_existing: true, preserve_conferidos: true)
  end

  def down
    # Dados oficiais permanecem; remoção manual se necessário.
  end
end
