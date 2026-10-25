# frozen_string_literal: true

namespace :financeiro do
  desc "Importa planilha financeira (.xlsx). Uso: bin/rails financeiro:import[path] FORCE=1"
  task :import, [:path] => :environment do |_t, args|
    path = args[:path].presence || ENV["PLANILHA"].presence
    if path.blank?
      default = Rails.root.join("public/planilhas-migracao/MESC-Financeiro.xlsx")
      path = default.to_s if File.file?(default)
    end
    raise "Informe o caminho: bin/rails financeiro:import[public/planilhas-migracao/MESC-Financeiro.xlsx]" if path.blank?

    force = ENV["FORCE"].to_s == "1"
    apenas_intencoes = ENV["APENAS"].to_s.casecmp("intencoes").zero?
    $stdout.sync = true
    modo = force ? " [FORCE]" : ""
    modo += " [APENAS=intencoes]" if apenas_intencoes
    puts "[financeiro:import] Iniciando (#{path})#{modo}…"
    importacao = Financeiro::ImportPlanilhaService.call(path, force: force, apenas_intencoes: apenas_intencoes)
    puts "Importação #{importacao.status} — checksum #{importacao.checksum}"
    puts JSON.pretty_generate(importacao.relatorio)
  end

  desc "Cria plano de contas padrão e conta corrente"
  task seed: :environment do
    Financeiro::PlanoContaSeedService.call
    ContaCorrente.padrao
    puts "Plano de contas: #{PlanoConta.count} contas"
  end

  desc "Zera lançamentos, importações e auditorias; reinicia IDs (PostgreSQL). PLANO=1 também recria plano de contas"
  task reset: :environment do
    reset_plano = ENV["PLANO"].to_s == "1"
    $stdout.sync = true
    puts "[financeiro:reset] Limpando dados financeiros#{reset_plano ? ' (+ plano de contas)' : ''}…"
    resumo = Financeiro::ResetDadosService.call(plano_contas: reset_plano)
    puts "[financeiro:reset] Antes: #{resumo[:antes].inspect}"
    puts "[financeiro:reset] Depois: #{resumo.except(:antes).inspect}"
    puts "[financeiro:reset] Concluído."
  end

  desc "Reset completo + importação da planilha. FORCE=1 implícito. Uso: bin/rails financeiro:reimport[path]"
  task :reimport, [:path] => :environment do |_t, args|
    ENV["FORCE"] = "1"
    Rake::Task["financeiro:reset"].invoke
    Rake::Task["financeiro:import"].reenable
    Rake::Task["financeiro:import"].invoke(args[:path])
  end
end
