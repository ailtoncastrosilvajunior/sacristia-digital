# frozen_string_literal: true

class CreateLiturgiaDias < ActiveRecord::Migration[8.1]
  def change
    create_table :liturgia_dias do |t|
      t.date :data, null: false
      t.string :titulo
      t.string :cor
      t.string :santo_nome
      t.text :santo_descricao
      # text + serialize JSON: o servidor PG de desenvolvimento não expõe o tipo jsonb
      t.text :leituras, default: "[]"
      t.text :leituras_conferencia, default: "[]"
      t.text :divergencias, default: "[]"
      t.string :fonte
      t.string :fonte_url
      t.string :fonte_conferencia
      t.string :status, null: false, default: "rascunho"
      t.references :validado_por, foreign_key: { to_table: :users }
      t.datetime :validado_em
      t.datetime :buscado_em
      t.text :observacoes

      t.timestamps
    end

    add_index :liturgia_dias, :data, unique: true
    add_index :liturgia_dias, :status
  end
end
