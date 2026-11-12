# frozen_string_literal: true

namespace :instituicoes do
  desc "Provisiona tenant: slug nome plano_codigo [admin_email]. Ex.: rake instituicoes:provision[saovicente,\"Paróquia São Vicente\",escala_liturgia,admin@paroquia.local]"
  task :provision, %i[slug nome plano admin_email] => :environment do |_t, args|
    slug = args[:slug]
    nome = args[:nome]
    plano = args[:plano]
    admin_email = args[:admin_email]

    abort "Uso: rake instituicoes:provision[slug,nome,plano_codigo,admin_email_opcional]" if slug.blank? || nome.blank? || plano.blank?

    result = Instituicoes::Provisioner.call(
      slug: slug,
      nome: nome,
      plano_codigo: plano,
      admin_email: admin_email
    )

    inst = result.instituicao
    base = ENV.fetch("INSTITUICAO_BASE_DOMAIN", "sacristia-digital.net.br")
    puts "Instituição #{result.created ? 'criada' : 'já existia'}: #{inst.nome} (#{inst.slug})"
    puts "Plano: #{result.plano.nome} (#{result.plano.codigo})"
    puts "URL: https://#{inst.slug}.#{base}"
  end
end
