# frozen_string_literal: true

class CreateEquipes < ActiveRecord::Migration[8.0]
  def change
    create_table :equipes do |t|
      t.string :nome, null: false
      t.text :observacoes

      t.timestamps
    end
  end
end
