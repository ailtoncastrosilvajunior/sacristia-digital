# frozen_string_literal: true

class CreateCalendarioBase < ActiveRecord::Migration[8.0]
  def change
    create_table :calendario_base do |t|
      t.integer :dia_da_semana, null: false
      t.time :horario, null: false
      t.integer :quantidade_ministros, null: false, default: 2
      t.references :sacerdote, foreign_key: true
      t.decimal :valor_esportula_override, precision: 10, scale: 2
      t.boolean :ativo, default: true, null: false
      t.text :observacoes

      t.timestamps
    end

    add_index :calendario_base, [:dia_da_semana, :ativo]
  end
end
