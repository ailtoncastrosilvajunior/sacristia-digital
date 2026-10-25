# frozen_string_literal: true

class CreateFinanceiro < ActiveRecord::Migration[8.1]
  def change
    create_table :plano_contas do |t|
      t.string :codigo, null: false
      t.string :nome, null: false
      t.string :natureza, null: false
      t.boolean :sintetica, default: false, null: false
      t.bigint :conta_pai_id
      t.integer :ordem, default: 0, null: false
      t.boolean :ativo, default: true, null: false
      t.timestamps
    end
    add_index :plano_contas, :codigo, unique: true
    add_index :plano_contas, :conta_pai_id
    add_foreign_key :plano_contas, :plano_contas, column: :conta_pai_id

    create_table :contas_correntes do |t|
      t.string :nome, null: false
      t.decimal :saldo_inicial, precision: 12, scale: 2, default: "0.0", null: false
      t.date :data_saldo_inicial, null: false
      t.boolean :ativo, default: true, null: false
      t.timestamps
    end

    create_table :importacoes_financeiras do |t|
      t.string :checksum, null: false
      t.string :arquivo_nome
      t.string :status, default: "pendente", null: false
      t.text :relatorio, default: "{}", null: false
      t.datetime :concluida_em
      t.timestamps
    end
    add_index :importacoes_financeiras, :checksum, unique: true

    create_table :lancamentos_caixa do |t|
      t.references :conta_corrente, null: false, foreign_key: { to_table: :contas_correntes }
      t.string :natureza, null: false
      t.date :data, null: false
      t.decimal :valor_total, precision: 12, scale: 2, default: "0.0", null: false
      t.string :status, default: "confirmado", null: false
      t.bigint :evento_escala_id
      t.string :contado_por
      t.string :fornecedor
      t.boolean :tem_documento_fiscal, default: false, null: false
      t.boolean :tem_recibo, default: false, null: false
      t.text :observacoes
      t.bigint :registro_esportula_id
      t.bigint :importacao_financeira_id
      t.string :planilha_aba
      t.integer :planilha_linha
      t.timestamps
    end
    add_index :lancamentos_caixa, :data
    add_index :lancamentos_caixa, :natureza
    add_index :lancamentos_caixa, :status
    add_index :lancamentos_caixa, :evento_escala_id
    add_index :lancamentos_caixa, :registro_esportula_id, unique: true, where: "registro_esportula_id IS NOT NULL"
    add_foreign_key :lancamentos_caixa, :evento_escala
    add_foreign_key :lancamentos_caixa, :registro_esportulas, column: :registro_esportula_id
    add_foreign_key :lancamentos_caixa, :importacoes_financeiras, column: :importacao_financeira_id

    create_table :itens_lancamento do |t|
      t.references :lancamento_caixa, null: false, foreign_key: { to_table: :lancamentos_caixa }
      t.references :plano_conta, null: false, foreign_key: { to_table: :plano_contas }
      t.text :descricao
      t.decimal :quantidade, precision: 12, scale: 4, default: "1.0", null: false
      t.decimal :preco_unitario, precision: 12, scale: 4, default: "0.0", null: false
      t.decimal :valor, precision: 12, scale: 2, null: false
      t.integer :ordem, default: 0, null: false
      t.timestamps
    end

    create_table :auditorias_financeiras do |t|
      t.references :user, foreign_key: true
      t.string :registro_type, null: false
      t.bigint :registro_id, null: false
      t.string :acao, null: false
      t.text :payload, default: "{}", null: false
      t.timestamps
    end
    add_index :auditorias_financeiras, %i[registro_type registro_id]

    create_table :financeiro_configuracoes do |t|
      t.datetime :migrado_em
      t.timestamps
    end
  end
end
