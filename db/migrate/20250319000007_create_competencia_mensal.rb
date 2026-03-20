# frozen_string_literal: true

class CreateCompetenciaMensal < ActiveRecord::Migration[8.0]
  def change
    create_table :competencia_mensal do |t|
      t.integer :ano, null: false
      t.integer :mes, null: false
      t.boolean :escala_gerada, default: false, null: false

      t.timestamps
    end

    add_index :competencia_mensal, [:ano, :mes], unique: true
  end
end
