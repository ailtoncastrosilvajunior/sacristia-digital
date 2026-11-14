# frozen_string_literal: true

class AddProclamacaoPalavraToCalendarioBase < ActiveRecord::Migration[8.1]
  def change
    add_column :calendario_base, :proclamacao_palavra, :text
  end
end
