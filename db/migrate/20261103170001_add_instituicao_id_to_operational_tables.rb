# frozen_string_literal: true

class AddInstituicaoIdToOperationalTables < ActiveRecord::Migration[8.1]
  TABLES = %i[
    users
    ministros
    sacerdotes
    tipo_servicos
    calendario_base
    competencia_mensal
    contas_correntes
    destinatarios_esportula
    plano_contas
    financeiro_configuracoes
    importacoes_financeiras
    lancamentos_caixa
    lote_pagamento_esportulas
    plantao_periodos
    oferta_apoios
    solicitacao_cadastros
  ].freeze

  COMPETENCIA_IDX = "index_competencia_mensal_on_instituicao_ano_mes"
  USERS_EMAIL_IDX = "index_users_on_instituicao_id_and_email"
  MINISTROS_EMAIL_IDX = "index_ministros_on_instituicao_id_and_email"
  PLANO_CONTAS_IDX = "index_plano_contas_on_instituicao_id_and_codigo"

  def up
    TABLES.each do |table|
      next if column_exists?(table, :instituicao_id)

      add_reference table, :instituicao, foreign_key: { to_table: :instituicoes }, null: true
    end

    remove_competencia_ano_mes_index

    add_index :competencia_mensal, %i[instituicao_id ano mes], unique: true, name: COMPETENCIA_IDX unless index_exists?(
      :competencia_mensal, name: COMPETENCIA_IDX
    )

    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, %i[instituicao_id email], unique: true, name: USERS_EMAIL_IDX unless index_exists?(
      :users, name: USERS_EMAIL_IDX
    )

    remove_index :ministros, name: "index_ministros_on_email_unique" if index_exists?(
      :ministros, name: "index_ministros_on_email_unique"
    )
    unless index_exists?(:ministros, name: MINISTROS_EMAIL_IDX)
      add_index :ministros, %i[instituicao_id email],
                unique: true,
                where: "email IS NOT NULL",
                name: MINISTROS_EMAIL_IDX
    end

    remove_index :plano_contas, :codigo if index_exists?(:plano_contas, :codigo)
    add_index :plano_contas, %i[instituicao_id codigo], unique: true, name: PLANO_CONTAS_IDX unless index_exists?(
      :plano_contas, name: PLANO_CONTAS_IDX
    )
  end

  def down
    remove_index :plano_contas, name: PLANO_CONTAS_IDX if index_exists?(:plano_contas, name: PLANO_CONTAS_IDX)
    add_index :plano_contas, :codigo, unique: true unless index_exists?(:plano_contas, :codigo)

    remove_index :ministros, name: MINISTROS_EMAIL_IDX if index_exists?(:ministros, name: MINISTROS_EMAIL_IDX)
    add_index :ministros, :email, unique: true, where: "email IS NOT NULL", name: "index_ministros_on_email_unique" unless index_exists?(
      :ministros, name: "index_ministros_on_email_unique"
    )

    remove_index :users, name: USERS_EMAIL_IDX if index_exists?(:users, name: USERS_EMAIL_IDX)
    add_index :users, :email, unique: true unless index_exists?(:users, :email)

    remove_index :competencia_mensal, name: COMPETENCIA_IDX if index_exists?(:competencia_mensal, name: COMPETENCIA_IDX)
    add_index :competencia_mensal, %i[ano mes], unique: true unless index_exists?(:competencia_mensal, %i[ano mes])

    TABLES.reverse_each do |table|
      remove_reference table, :instituicao, foreign_key: { to_table: :instituicoes } if column_exists?(table, :instituicao_id)
    end
  end

  private

  def remove_competencia_ano_mes_index
    if index_exists?(:competencia_mensal, %i[ano mes])
      remove_index :competencia_mensal, column: %i[ano mes]
    elsif index_exists?(:competencia_mensal, name: "index_competencia_mensal_on_ano_and_mes")
      remove_index :competencia_mensal, name: "index_competencia_mensal_on_ano_and_mes"
    end
  end
end
