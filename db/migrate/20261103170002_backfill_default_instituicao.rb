# frozen_string_literal: true

class BackfillDefaultInstituicao < ActiveRecord::Migration[8.1]
  RECURSOS_COMPLETO = {
    "escala_mesc" => true,
    "liturgia_cartaz" => true,
    "esportulas" => true,
    "financeiro_caixa" => true,
    "escala_extra" => true,
    "painel_sacerdote" => true
  }.freeze

  TABLES = AddInstituicaoIdToOperationalTables::TABLES

  def up
    now = Time.current
    plano = Plano.create!(
      codigo: "completo",
      nome: "Completo",
      descricao: "Escala MESC, liturgia e cartaz, espórtulas e controle de caixa.",
      preco_mensal_centavos: 0,
      recursos: RECURSOS_COMPLETO
    )

    inst = Instituicao.create!(
      tipo: "comunidade",
      slug: "facedecristo",
      nome: "Comunidade Face de Cristo",
      nome_curto: "Face de Cristo",
      slogan_rodape: "Face de Cristo resplandecei em nós",
      nome_recibos: ENV.fetch("PAROQUIA_NOME", "Paróquia"),
      ativa: true,
      assinatura_status: "ativa"
    )

    InstituicaoPlano.create!(
      instituicao: inst,
      plano: plano,
      vigencia_inicio: now,
      modulos_vigencia_inicio: now,
      preco_mensal_centavos: plano.preco_mensal_centavos,
      recursos_snapshot: plano.recursos,
      status: "vigente"
    )

    TABLES.each do |table|
      execute <<~SQL.squish
        UPDATE #{table} SET instituicao_id = #{inst.id} WHERE instituicao_id IS NULL
      SQL
    end
  end

  def down
    TABLES.each do |table|
      execute "UPDATE #{table} SET instituicao_id = NULL"
    end
    InstituicaoPlano.delete_all
    Instituicao.delete_all
    Plano.delete_all
  end
end
