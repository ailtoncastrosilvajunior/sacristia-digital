# frozen_string_literal: true

class CreatePlantaoPeriodos < ActiveRecord::Migration[8.0]
  def change
    create_table :plantao_periodos do |t|
      t.references :competencia_mensal, null: false, foreign_key: true
      t.references :equipe, null: false, foreign_key: true
      t.integer :dia_inicio, null: false
      t.integer :dia_fim, null: false

      t.timestamps
    end

    add_index :plantao_periodos, [:competencia_mensal_id, :dia_inicio]
  end
end
