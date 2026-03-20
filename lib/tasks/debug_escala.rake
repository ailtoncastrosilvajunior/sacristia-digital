# frozen_string_literal: true

namespace :escala do
  desc "Debug: lista calendario_base por tipo e verifica se Confissão está no banco"
  task debug: :environment do
    puts "\n=== Calendário Base por tipo ==="
    CalendarioBase.ativos.group(:tipo).count.each do |tipo, count|
      puts "  #{tipo}: #{count} entradas"
    end

    puts "\n=== TipoServico Confissão ==="
    ts = TipoServico.find_by(nome: "Confissão")
    if ts
      puts "  Encontrado: id=#{ts.id}, ativo=#{ts.ativo}"
    else
      puts "  NÃO ENCONTRADO - será criado na próxima geração"
    end

    puts "\n=== Última competência - evento_escalas por tipo_servico ==="
    comp = CompetenciaMensal.ordenados.first
    return puts "  Nenhuma competência" unless comp

    comp.evento_escalas.joins(:tipo_servico).group("tipo_servicos.nome").count.each do |nome, count|
      puts "  #{nome}: #{count} eventos"
    end
    puts ""
  end
end
