# frozen_string_literal: true

class CreateEscalaMinistros < ActiveRecord::Migration[8.0]
  def change
    create_table :escala_ministros do |t|
      t.references :evento_escala, null: false, foreign_key: true
      t.references :ministro, null: false, foreign_key: true
      t.boolean :confirmado, default: false, null: false
      t.datetime :confirmado_em

      t.timestamps
    end

    add_index :escala_ministros, [:evento_escala_id, :ministro_id], unique: true
  end
end
