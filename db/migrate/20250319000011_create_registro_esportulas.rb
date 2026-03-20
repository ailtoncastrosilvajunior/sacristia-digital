# frozen_string_literal: true

class CreateRegistroEsportulas < ActiveRecord::Migration[8.0]
  def change
    create_table :registro_esportulas do |t|
      t.references :sacerdote, null: false, foreign_key: true
      t.references :evento_escala, foreign_key: true
      t.date :data, null: false
      t.string :forma_pagamento
      t.decimal :valor, precision: 10, scale: 2, null: false
      t.string :status, default: "pendente", null: false
      t.integer :competencia_ano
      t.integer :competencia_mes

      t.timestamps
    end

    add_index :registro_esportulas, [:sacerdote_id, :competencia_ano, :competencia_mes]
    add_index :registro_esportulas, :status
  end
end
