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

ActiveRecord::Schema[8.1].define(version: 2026_03_26_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "equipe_ministros", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "equipe_id", null: false
    t.bigint "ministro_id", null: false
    t.integer "ordem", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "equipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dia_fim"
    t.integer "dia_inicio"
    t.string "nome", null: false
    t.text "observacoes"
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
    t.datetime "updated_at", null: false
    t.index ["ministro_id"], name: "index_escala_ministros_on_ministro_id"
  end

  create_table "evento_escala", force: :cascade do |t|
    t.bigint "competencia_mensal_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.text "descricao"
    t.bigint "equipe_id"
    t.time "horario", null: false
    t.string "local"
    t.text "observacoes"
    t.integer "quantidade_ministros", default: 2, null: false
    t.bigint "sacerdote_id"
    t.string "status", default: "pendente", null: false
    t.string "tipo_escala", default: "ordinaria", null: false
    t.bigint "tipo_servico_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_esportula", precision: 10, scale: 2
  end

  create_table "ministros", force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "nome", null: false
    t.text "observacoes"
    t.string "sexo"
    t.string "telefone"
    t.datetime "updated_at", null: false
  end

  create_table "plantao_periodos", force: :cascade do |t|
    t.bigint "competencia_mensal_id", null: false
    t.datetime "created_at", null: false
    t.integer "dia_fim", null: false
    t.integer "dia_inicio", null: false
    t.bigint "equipe_id", null: false
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

  add_foreign_key "equipe_ministros", "equipes"
  add_foreign_key "equipe_ministros", "ministros"
  add_foreign_key "escala_ministros", "evento_escala"
  add_foreign_key "escala_ministros", "ministros"
  add_foreign_key "evento_escala", "competencia_mensal"
  add_foreign_key "evento_escala", "equipes"
  add_foreign_key "evento_escala", "sacerdotes"
  add_foreign_key "evento_escala", "tipo_servicos"
  add_foreign_key "plantao_periodos", "competencia_mensal"
  add_foreign_key "plantao_periodos", "equipes"
  add_foreign_key "registro_esportulas", "evento_escala"
  add_foreign_key "registro_esportulas", "sacerdotes"
  add_foreign_key "users", "ministros"
  add_foreign_key "users", "sacerdotes"
end
