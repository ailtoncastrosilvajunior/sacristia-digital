# frozen_string_literal: true

puts "🌿 Sacristia Digital - Seeds iniciais"
puts "=" * 50

# Tipos de Serviço
puts "\n📋 Criando tipos de serviço..."
tipo_servicos = [
  { nome: "Missa", tipo_escala: "ordinaria", cor_etiqueta: "#2563eb" },
  { nome: "Confissão", tipo_escala: "ordinaria", cor_etiqueta: "#7c3aed" },
  { nome: "Missa 7º dia", tipo_escala: "extra", cor_etiqueta: "#0891b2" },
  { nome: "Batizado", tipo_escala: "extra", cor_etiqueta: "#db2777" },
  { nome: "Casamento", tipo_escala: "extra", cor_etiqueta: "#ca8a04" },
  { nome: "Celebração da palavra", tipo_escala: "extra", cor_etiqueta: "#059669" },
  { nome: "Comunhão a enfermo", tipo_escala: "extra", cor_etiqueta: "#ea580c" },
  { nome: "Exposição e Recolhimento do Santíssimo", tipo_escala: "extra", cor_etiqueta: "#475569" }
]

tipo_servicos.each do |attrs|
  TipoServico.find_or_create_by!(nome: attrs[:nome]) do |t|
    t.tipo_escala = attrs[:tipo_escala]
    t.cor_etiqueta = attrs[:cor_etiqueta]
    t.ativo = true
  end
end
puts "   ✓ #{TipoServico.count} tipos de serviço"

# Sacerdotes
puts "\n⛪ Criando sacerdotes..."
sacerdotes_data = [
  { nome: "Pe. João Silva", email: "joao@paroquia.local", telefone: "(11) 99999-1001", forma_esportula: "por_missa", valor_esportula_padrao: 150.00 },
  { nome: "Pe. Maria Santos", email: "maria@paroquia.local", telefone: "(11) 99999-1002", forma_esportula: "por_periodo", valor_esportula_padrao: 2000.00 },
  { nome: "Pe. José Oliveira", email: "jose@paroquia.local", telefone: "(11) 99999-1003", forma_esportula: "por_missa", valor_esportula_padrao: 120.00 }
]

sacerdotes = []
sacerdotes_data.each do |attrs|
  s = Sacerdote.find_or_create_by!(nome: attrs[:nome]) do |sacerdote|
    sacerdote.nome = attrs[:nome]
    sacerdote.telefone = attrs[:telefone]
    sacerdote.forma_esportula = attrs[:forma_esportula]
    sacerdote.valor_esportula_padrao = attrs[:valor_esportula_padrao]
    sacerdote.ativo = true
  end
  sacerdotes << s
end
puts "   ✓ #{Sacerdote.count} sacerdotes"

# Ministros
puts "\n👥 Criando ministros..."
ministros_data = [
  { nome: "Ana Paula Costa", email: "ana@email.com", telefone: "(11) 98888-1001", sexo: "Feminino" },
  { nome: "Bruno Mendes", email: "bruno@email.com", telefone: "(11) 98888-1002", sexo: "Masculino" },
  { nome: "Carla Ferreira", email: "carla@email.com", telefone: "(11) 98888-1003", sexo: "Feminino" },
  { nome: "Daniel Souza", email: "daniel@email.com", telefone: "(11) 98888-1004", sexo: "Masculino" },
  { nome: "Elena Rodrigues", email: "elena@email.com", telefone: "(11) 98888-1005", sexo: "Feminino" },
  { nome: "Fernando Lima", email: "fernando@email.com", telefone: "(11) 98888-1006", sexo: "Masculino" },
  { nome: "Gabriela Alves", email: "gabriela@email.com", telefone: "(11) 98888-1007", sexo: "Feminino" },
  { nome: "Henrique Pereira", email: "henrique@email.com", telefone: "(11) 98888-1008", sexo: "Masculino" },
  { nome: "Isabela Martins", email: "isabela@email.com", telefone: "(11) 98888-1009", sexo: "Feminino" },
  { nome: "João Pedro Nascimento", email: "joaopedro@email.com", telefone: "(11) 98888-1010", sexo: "Masculino" }
]

ministros = []
ministros_data.each do |attrs|
  m = Ministro.find_or_create_by!(email: attrs[:email]) do |ministro|
    ministro.nome = attrs[:nome]
    ministro.telefone = attrs[:telefone]
    ministro.sexo = attrs[:sexo]
    ministro.ativo = true
  end
  ministros << m
end
puts "   ✓ #{Ministro.count} ministros"

# Calendário Base
puts "\n📅 Criando calendário base de missas..."
tipo_missa = TipoServico.find_by!(nome: "Missa")
pe_joao = Sacerdote.find_by!(nome: "Pe. João Silva")
pe_maria = Sacerdote.find_by!(nome: "Pe. Maria Santos")

calendario_base = [
  { dia_da_semana: 0, horario: "07:00", quantidade_ministros: 4, sacerdote: pe_joao },
  { dia_da_semana: 0, horario: "19:00", quantidade_ministros: 4, sacerdote: pe_maria },
  { dia_da_semana: 1, horario: "19:00", quantidade_ministros: 2, sacerdote: pe_joao },
  { dia_da_semana: 2, horario: "19:00", quantidade_ministros: 2, sacerdote: nil },
  { dia_da_semana: 3, horario: "19:00", quantidade_ministros: 2, sacerdote: pe_maria },
  { dia_da_semana: 4, horario: "19:00", quantidade_ministros: 2, sacerdote: nil },
  { dia_da_semana: 5, horario: "19:00", quantidade_ministros: 2, sacerdote: pe_joao },
  { dia_da_semana: 6, horario: "18:00", quantidade_ministros: 2, sacerdote: pe_maria }
]

calendario_base.each do |attrs|
  CalendarioBase.find_or_create_by!(
    dia_da_semana: attrs[:dia_da_semana],
    horario: attrs[:horario],
    tipo: attrs[:tipo] || "missa"
  ) do |cb|
    cb.quantidade_ministros = attrs[:quantidade_ministros]
    cb.sacerdote_id = attrs[:sacerdote]&.id
    cb.ativo = true
  end
end
puts "   ✓ #{CalendarioBase.count} entradas no calendário base"

# Equipes de plantão
puts "\n👥 Criando equipes de plantão..."
equipes_data = [
  { nome: "Equipe A" },
  { nome: "Equipe B" },
  { nome: "Equipe C" },
  { nome: "Equipe D" },
  { nome: "Equipe E" }
]

equipes = []
equipes_data.each do |attrs|
  e = Equipe.find_or_create_by!(nome: attrs[:nome])
  equipes << e
end

# Distribuir ministros nas equipes
ministros_ativos = Ministro.ativos.to_a
equipes.each_with_index do |equipe, idx|
  ministros_ativos.each_with_index do |ministro, m_idx|
    next unless (m_idx % equipes.size) == idx
    EquipeMinistro.find_or_create_by!(equipe: equipe, ministro: ministro) do |em|
      em.ordem = m_idx
    end
  end
end
puts "   ✓ #{Equipe.count} equipes com ministros vinculados"

# Usuários e autenticação
puts "\n🔐 Criando usuários..."
senha = "123456"

admin_user = User.find_or_create_by!(email: "admin@sacristiadigital.local") do |u|
  u.nome = "Administrador"
  u.perfil = "admin"
  u.password = senha
  u.password_confirmation = senha
end

coordenador_user = User.find_or_create_by!(email: "coordenador@sacristiadigital.local") do |u|
  u.nome = "Coordenador MESC"
  u.perfil = "coordenador"
  u.password = senha
  u.password_confirmation = senha
end

# Vincular um ministro ao primeiro ministro para login
ministro_user = User.find_or_create_by!(email: "ministro@sacristiadigital.local") do |u|
  u.nome = ministros.first.nome
  u.perfil = "ministro"
  u.ministro_id = ministros.first.id
  u.password = senha
  u.password_confirmation = senha
end

puts "   ✓ Usuários criados:"
puts "      - admin@sacristiadigital.local (admin) - senha: #{senha}"
puts "      - coordenador@sacristiadigital.local (coordenador) - senha: #{senha}"
puts "      - ministro@sacristiadigital.local (ministro) - senha: #{senha}"

# Competência do mês atual
puts "\n📆 Criando competência do mês atual..."
hoje = Date.current
competencia = CompetenciaMensal.find_or_create_by!(ano: hoje.year, mes: hoje.month)
puts "   ✓ Competência #{competencia.label}"

puts "\n" + "=" * 50
puts "✅ Seeds concluídos com sucesso!"
puts "=" * 50
