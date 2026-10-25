# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_25_123000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "auditorias_financeiras", force: :cascade do |t|
    t.string "acao", null: false
    t.datetime "created_at", null: false
    t.text "payload", default: "{}", null: false
    t.bigint "registro_id", null: false
    t.string "registro_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["registro_type", "registro_id"], name: "index_auditorias_financeiras_on_registro_type_and_registro_id"
    t.index ["user_id"], name: "index_auditorias_financeiras_on_user_id"
  end

  create_table "calendario_base", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "dia_da_semana", null: false
    t.time "horario", null: false
    t.text "observacoes"
    t.integer "quantidade_ministros", default: 2, null: false
    t.bigint "sacerdote_id"
    t.string "tipo", default: "missa", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_esportula_override", precision: 10, scale: 2
  end

  create_table "competencia_mensal", force: :cascade do |t|
    t.integer "ano", null: false
    t.datetime "created_at", null: false
    t.boolean "escala_gerada", default: false, null: false
    t.boolean "escala_liberada", default: false, null: false
    t.integer "mes", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contas_correntes", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.date "data_saldo_inicial", null: false
    t.string "nome", null: false
    t.decimal "saldo_inicial", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
  end

  create_table "escala_ministros", force: :cascade do |t|
    t.boolean "adoracao", default: false, null: false
    t.boolean "confirmado", default: false, null: false
    t.datetime "confirmado_em"
    t.boolean "coordenador", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "evento_escala_id", null: false
    t.bigint "ministro_id", null: false
    t.bigint "ministro_original_id"
    t.string "motivo_troca"
    t.datetime "updated_at", null: false
    t.index ["evento_escala_id", "ministro_id"], name: "idx_escala_ministros_evento_ministro", unique: true
    t.index ["ministro_id"], name: "index_escala_ministros_on_ministro_id"
    t.index ["ministro_original_id"], name: "index_escala_ministros_on_ministro_original_id"
  end

  create_table "evento_escala", force: :cascade do |t|
    t.bigint "competencia_mensal_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.text "descricao"
    t.time "horario", null: false
    t.string "local"
    t.text "observacoes"
    t.bigint "plantao_periodo_id"
    t.integer "quantidade_ministros", default: 2, null: false
    t.bigint "sacerdote_id"
    t.string "status", default: "confirmado", null: false
    t.string "tipo_escala", default: "ordinaria", null: false
    t.bigint "tipo_servico_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_esportula", precision: 10, scale: 2
    t.index ["plantao_periodo_id"], name: "index_evento_escala_on_plantao_periodo_id"
  end

  create_table "financeiro_configuracoes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "migrado_em"
    t.datetime "updated_at", null: false
  end

  create_table "importacoes_financeiras", force: :cascade do |t|
    t.string "arquivo_nome"
    t.string "checksum", null: false
    t.datetime "concluida_em"
    t.datetime "created_at", null: false
    t.text "relatorio", default: "{}", null: false
    t.string "status", default: "pendente", null: false
    t.datetime "updated_at", null: false
    t.index ["checksum"], name: "index_importacoes_financeiras_on_checksum", unique: true
  end

  create_table "itens_lancamento", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descricao"
    t.bigint "lancamento_caixa_id", null: false
    t.integer "ordem", default: 0, null: false
    t.bigint "plano_conta_id", null: false
    t.decimal "preco_unitario", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "quantidade", precision: 12, scale: 4, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 12, scale: 2, null: false
    t.decimal "valor_desconto", precision: 12, scale: 2, default: "0.0", null: false
    t.index ["lancamento_caixa_id"], name: "index_itens_lancamento_on_lancamento_caixa_id"
    t.index ["plano_conta_id"], name: "index_itens_lancamento_on_plano_conta_id"
  end

  create_table "lancamentos_caixa", force: :cascade do |t|
    t.bigint "conta_corrente_id", null: false
    t.string "contado_por"
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "evento_escala_id"
    t.string "fornecedor"
    t.bigint "importacao_financeira_id"
    t.string "natureza", null: false
    t.text "observacoes"
    t.string "planilha_aba"
    t.integer "planilha_linha"
    t.bigint "registro_esportula_id"
    t.string "status", default: "confirmado", null: false
    t.boolean "tem_documento_fiscal", default: false, null: false
    t.boolean "tem_recibo", default: false, null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_total", precision: 12, scale: 2, default: "0.0", null: false
    t.index ["conta_corrente_id"], name: "index_lancamentos_caixa_on_conta_corrente_id"
    t.index ["data"], name: "index_lancamentos_caixa_on_data"
    t.index ["evento_escala_id"], name: "index_lancamentos_caixa_on_evento_escala_id"
    t.index ["natureza"], name: "index_lancamentos_caixa_on_natureza"
    t.index ["registro_esportula_id"], name: "index_lancamentos_caixa_on_registro_esportula_id", unique: true, where: "(registro_esportula_id IS NOT NULL)"
    t.index ["status"], name: "index_lancamentos_caixa_on_status"
  end

  create_table "liturgia_dias", force: :cascade do |t|
    t.datetime "buscado_em"
    t.string "cor"
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.text "divergencias", default: "[]"
    t.string "fonte"
    t.string "fonte_conferencia"
    t.string "fonte_url"
    t.text "leituras", default: "[]"
    t.text "leituras_conferencia", default: "[]"
    t.text "observacoes"
    t.text "santo_descricao"
    t.string "santo_nome"
    t.string "status", default: "rascunho", null: false
    t.string "titulo"
    t.datetime "updated_at", null: false
    t.datetime "validado_em"
    t.bigint "validado_por_id"
    t.index ["data"], name: "index_liturgia_dias_on_data", unique: true
    t.index ["status"], name: "index_liturgia_dias_on_status"
    t.index ["validado_por_id"], name: "index_liturgia_dias_on_validado_por_id"
  end

  create_table "ministros", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "exibir_ano_nascimento", default: false, null: false
    t.integer "nascimento_ano"
    t.integer "nascimento_dia"
    t.integer "nascimento_mes"
    t.string "nome", null: false
    t.string "nome_completo"
    t.text "observacoes"
    t.string "sexo"
    t.string "telefone"
    t.datetime "updated_at", null: false
    t.index ["nascimento_mes", "nascimento_dia"], name: "index_ministros_on_nascimento_mes_and_nascimento_dia"
  end

  create_table "oferta_apoios", force: :cascade do |t|
    t.bigint "competencia_mensal_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "ministro_id", null: false
    t.string "status", default: "ativa", null: false
    t.datetime "updated_at", null: false
    t.index ["competencia_mensal_id"], name: "index_oferta_apoios_on_competencia_mensal_id"
    t.index ["ministro_id", "data"], name: "index_oferta_apoios_on_ministro_id_and_data", unique: true
    t.index ["ministro_id"], name: "index_oferta_apoios_on_ministro_id"
    t.index ["status"], name: "index_oferta_apoios_on_status"
  end

  create_table "plano_contas", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.string "codigo", null: false
    t.bigint "conta_pai_id"
    t.datetime "created_at", null: false
    t.string "natureza", null: false
    t.string "nome", null: false
    t.integer "ordem", default: 0, null: false
    t.boolean "sintetica", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["codigo"], name: "index_plano_contas_on_codigo", unique: true
    t.index ["conta_pai_id"], name: "index_plano_contas_on_conta_pai_id"
  end

  create_table "plantao_periodo_ministros", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ministro_id", null: false
    t.integer "ordem", default: 0, null: false
    t.bigint "plantao_periodo_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ministro_id"], name: "index_plantao_periodo_ministros_on_ministro_id"
    t.index ["plantao_periodo_id", "ministro_id"], name: "idx_plantao_periodo_ministros_unico", unique: true
    t.index ["plantao_periodo_id"], name: "index_plantao_periodo_ministros_on_plantao_periodo_id"
  end

  create_table "plantao_periodos", force: :cascade do |t|
    t.bigint "competencia_mensal_id", null: false
    t.datetime "created_at", null: false
    t.integer "dia_fim", null: false
    t.integer "dia_inicio", null: false
    t.datetime "updated_at", null: false
  end

  create_table "registro_esportulas", force: :cascade do |t|
    t.integer "competencia_ano"
    t.integer "competencia_mes"
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "evento_escala_id"
    t.string "forma_pagamento"
    t.bigint "sacerdote_id", null: false
    t.string "status", default: "pendente", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 10, scale: 2, null: false
  end

  create_table "sacerdotes", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "forma_esportula", default: "por_missa", null: false
    t.string "nome", null: false
    t.string "telefone"
    t.datetime "updated_at", null: false
    t.decimal "valor_esportula_padrao", precision: 10, scale: 2, default: "0.0"
  end

  create_table "solicitacao_cadastros", force: :cascade do |t|
    t.datetime "avaliado_em"
    t.bigint "avaliado_por_id"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password"
    t.boolean "exibir_ano_nascimento", default: false, null: false
    t.bigint "ministro_id"
    t.text "motivo_rejeicao"
    t.integer "nascimento_ano"
    t.integer "nascimento_dia"
    t.integer "nascimento_mes"
    t.string "nome", null: false
    t.string "nome_completo"
    t.string "sexo"
    t.string "status", default: "pendente", null: false
    t.string "telefone"
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "idx_solicitacao_cadastros_email_lower"
    t.index ["avaliado_por_id"], name: "index_solicitacao_cadastros_on_avaliado_por_id"
    t.index ["ministro_id"], name: "index_solicitacao_cadastros_on_ministro_id"
    t.index ["status"], name: "index_solicitacao_cadastros_on_status"
  end

  create_table "solicitacao_trocas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "escala_ministro_id", null: false
    t.text "motivo"
    t.datetime "respondido_em"
    t.string "status", default: "pendente", null: false
    t.bigint "substituto_id", null: false
    t.datetime "updated_at", null: false
    t.index ["escala_ministro_id"], name: "index_solicitacao_trocas_on_escala_ministro_id"
    t.index ["status"], name: "index_solicitacao_trocas_on_status"
    t.index ["substituto_id"], name: "index_solicitacao_trocas_on_substituto_id"
  end

  create_table "tipo_servicos", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.string "cor_etiqueta", default: "#64748b"
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.string "tipo_escala", default: "ordinaria", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.bigint "ministro_id"
    t.string "nome"
    t.string "perfis", default: [], null: false, array: true
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "sacerdote_id"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["perfis"], name: "index_users_on_perfis", using: :gin
    t.index ["sacerdote_id"], name: "index_users_on_sacerdote_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "auditorias_financeiras", "users"
  add_foreign_key "escala_ministros", "evento_escala"
  add_foreign_key "escala_ministros", "ministros"
  add_foreign_key "escala_ministros", "ministros", column: "ministro_original_id"
  add_foreign_key "evento_escala", "competencia_mensal"
  add_foreign_key "evento_escala", "plantao_periodos"
  add_foreign_key "evento_escala", "sacerdotes"
  add_foreign_key "evento_escala", "tipo_servicos"
  add_foreign_key "itens_lancamento", "lancamentos_caixa", column: "lancamento_caixa_id"
  add_foreign_key "itens_lancamento", "plano_contas"
  add_foreign_key "lancamentos_caixa", "contas_correntes", column: "conta_corrente_id"
  add_foreign_key "lancamentos_caixa", "evento_escala"
  add_foreign_key "lancamentos_caixa", "importacoes_financeiras", column: "importacao_financeira_id"
  add_foreign_key "lancamentos_caixa", "registro_esportulas"
  add_foreign_key "liturgia_dias", "users", column: "validado_por_id"
  add_foreign_key "oferta_apoios", "competencia_mensal"
  add_foreign_key "oferta_apoios", "ministros"
  add_foreign_key "plano_contas", "plano_contas", column: "conta_pai_id"
  add_foreign_key "plantao_periodo_ministros", "ministros"
  add_foreign_key "plantao_periodo_ministros", "plantao_periodos"
  add_foreign_key "plantao_periodos", "competencia_mensal"
  add_foreign_key "registro_esportulas", "evento_escala"
  add_foreign_key "registro_esportulas", "sacerdotes"
  add_foreign_key "solicitacao_cadastros", "ministros"
  add_foreign_key "solicitacao_cadastros", "users", column: "avaliado_por_id"
  add_foreign_key "solicitacao_trocas", "escala_ministros"
  add_foreign_key "solicitacao_trocas", "ministros", column: "substituto_id"
  add_foreign_key "users", "ministros"
  add_foreign_key "users", "sacerdotes"
end
