# frozen_string_literal: true

class AddProclamacaoPalavraToEventoEscala < ActiveRecord::Migration[8.1]
  def change
    add_column :evento_escala, :proclamacao_palavra, :text
  end
end
