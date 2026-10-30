# frozen_string_literal: true

class CreateIgmrParagrafos < ActiveRecord::Migration[7.2]
  def change
    create_table :igmr_paragrafos do |t|
      t.integer :numero, null: false
      t.text :texto, null: false
      t.string :fonte
      t.boolean :texto_conferido, null: false, default: false

      t.timestamps
    end

    add_index :igmr_paragrafos, :numero, unique: true
  end
end
