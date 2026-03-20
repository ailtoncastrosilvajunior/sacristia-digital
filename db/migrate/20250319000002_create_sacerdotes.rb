# frozen_string_literal: true

class CreateSacerdotes < ActiveRecord::Migration[8.0]
  def change
    create_table :sacerdotes do |t|
      t.string :nome, null: false
      t.string :email
      t.string :telefone
      t.string :forma_esportula, null: false, default: "por_missa"
      t.decimal :valor_esportula_padrao, precision: 10, scale: 2, default: 0
      t.boolean :ativo, default: true, null: false

      t.timestamps
    end

    add_index :sacerdotes, :ativo
  end
end
