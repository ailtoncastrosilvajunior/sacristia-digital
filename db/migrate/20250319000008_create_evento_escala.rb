# frozen_string_literal: true

class CreateEventoEscala < ActiveRecord::Migration[8.0]
  def change
    create_table :evento_escala do |t|
      t.references :competencia_mensal, null: false, foreign_key: true
      t.references :tipo_servico, null: false, foreign_key: { to_table: :tipo_servicos }
      t.date :data, null: false
      t.time :horario, null: false
      t.integer :quantidade_ministros, null: false, default: 2
      t.string :local
      t.text :descricao
      t.text :observacoes
      t.references :sacerdote, foreign_key: true
      t.decimal :valor_esportula, precision: 10, scale: 2
      t.references :equipe, foreign_key: true
      t.string :tipo_escala, null: false, default: "ordinaria"
      t.string :status, default: "pendente", null: false

      t.timestamps
    end

    add_index :evento_escala, [:competencia_mensal_id, :data, :horario]
    add_index :evento_escala, :tipo_escala
    add_index :evento_escala, :status
  end
end
