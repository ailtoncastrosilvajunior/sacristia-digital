# frozen_string_literal: true

class CreateMinistros < ActiveRecord::Migration[8.0]
  def change
    create_table :ministros do |t|
      t.string :nome, null: false
      t.string :email, null: false
      t.string :telefone
      t.string :sexo
      t.boolean :ativo, default: true, null: false
      t.text :observacoes

      t.timestamps
    end

    add_index :ministros, :email, unique: true
    add_index :ministros, :ativo
  end
end
