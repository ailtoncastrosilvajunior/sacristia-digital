# frozen_string_literal: true

namespace :igmr do
  desc "Importa os 399 parágrafos do JSON CNBB (upsert). Opções: UPDATE=0 para só criar novos"
  task import_fixture: :environment do
    update = ENV["UPDATE"] != "0"
    preserve = ENV["FORCE"] != "1"
    res = Liturgia::IgmrFixtureImportService.call(update_existing: update, preserve_conferidos: preserve)
    puts "#{res.criados} criado(s), #{res.atualizados} atualizado(s), #{res.ignorados} ignorado(s)."
  end

  desc "Importa parágrafos IGMR de CSV (numero;texto;fonte;texto_conferido). Ex.: bin/rails igmr:import[path.csv]"
  task :import, [:path] => :environment do |_t, args|
    path = args[:path].presence || Rails.root.join("db/fixtures/igmr_paragrafos.exemplo.csv")
    unless File.file?(path)
      abort "Arquivo não encontrado: #{path}"
    end

    File.open(path) do |io|
      res = Liturgia::IgmrImportService.call(io)
      puts res.resumo
      res.erros.each { |e| warn "  • #{e}" }
      exit 1 unless res.ok?
    end
  end
end
