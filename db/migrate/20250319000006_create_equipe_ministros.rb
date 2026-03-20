# frozen_string_literal: true

class CreateEquipeMinistros < ActiveRecord::Migration[8.0]
  def change
    create_table :equipe_ministros do |t|
      t.references :equipe, null: false, foreign_key: true
      t.references :ministro, null: false, foreign_key: true
      t.integer :ordem, default: 0

      t.timestamps
    end

    add_index :equipe_ministros, [:equipe_id, :ministro_id], unique: true
  end
end
