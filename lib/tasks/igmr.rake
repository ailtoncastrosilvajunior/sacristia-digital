# frozen_string_literal: true

namespace :igmr do
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
