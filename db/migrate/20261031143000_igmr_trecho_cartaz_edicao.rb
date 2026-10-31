# frozen_string_literal: true

class IgmrTrechoCartazEdicao < ActiveRecord::Migration[7.2]
  def change
    change_table :igmr_paragrafos, bulk: true do |t|
      t.text :trecho_cartaz
      t.string :edicao
    end
  end
end
